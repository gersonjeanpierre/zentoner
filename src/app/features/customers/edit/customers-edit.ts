import { Component, inject, signal, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators, FormArray } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';
import { CustomerService } from '../customer-service';
import { CustomerView } from '../../../core/customer/customer-model';
import camelCase from 'camelcase-keys';
import { generateCustomerCode } from '../utils/customer-utils';

@Component({
  selector: 'app-customers-edit',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  templateUrl: './customers-edit.html',
  styleUrls: ['./customers-edit.css'],
  host: {
    class: 'block',
  },
})
export class CustomersEditComponent implements OnInit {
  private readonly fb = inject(FormBuilder);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly customerService = inject(CustomerService);

  // Signals for state management
  customer = signal<CustomerView | null>(null);
  loading = signal(true);
  saving = signal(false);
  deleting = signal(false);
  error = signal<string | null>(null);
  success = signal(false);
  deleteError = signal<string | null>(null);
  deleteSuccess = signal(false);

  // Form
  form: FormGroup = this.fb.group({
    personType: [{value: '', disabled: true}],
    firstName: [''],
    lastName: [''],
    legalName: [''],
    phone: ['', Validators.required],
    email: [''],
    dni: [''],
    ce: [''],
    ruc: [''],
    customerCode: [{value: '', disabled: true}],
    customerType: ['NUEVO', Validators.required],
    notes: this.fb.array<FormGroup>([]),
  });

  get notesArray() {
    return this.form.get('notes') as FormArray<FormGroup>;
  }

  addNote() {
    this.notesArray.push(this.fb.group({ key: [''], value: [''] }));
  }

  removeNote(index: number) {
    this.notesArray.removeAt(index);
  }

  ngOnInit(): void {
    const id = this.route.snapshot.params['id'];
    if (id) {
      this.loadCustomer(id);
    } else {
      this.error.set('ID de cliente no proporcionado');
      this.loading.set(false);
    }
    this.form.get('firstName')?.valueChanges.subscribe(() => this.generateCode());
    this.form.get('lastName')?.valueChanges.subscribe(() => this.generateCode());
  }

  private async loadCustomer(id: string): Promise<void> {
    try {
      const customer = await this.customerService.getCustomerById(id);
      const camelCasedCustomer = camelCase(customer, { deep: true });

      console.log('Loaded customer:', camelCasedCustomer);
      this.customer.set(camelCasedCustomer);
      this.populateForm(camelCasedCustomer);
      this.loading.set(false);
    } catch (err: any) {
      console.error('Error loading customer:', err);
      this.error.set('Error al cargar el cliente');
      this.loading.set(false);
    }
  }

  private populateForm(customer: CustomerView): void {
    // Clear existing notes
    while (this.notesArray.length !== 0) {
      this.notesArray.removeAt(0);
    }

    // Populate notes from customer data
    if (customer.notes && typeof customer.notes === 'object') {
      Object.entries(customer.notes).forEach(([key, value]) => {
        this.notesArray.push(this.fb.group({ key: [key], value: [value] }));
      });
    }

    this.form.patchValue({
      personType: customer.personType,
      firstName: customer.firstName || '',
      lastName: customer.lastName || '',
      legalName: customer.legalName || '',
      phone: customer.phone || '',
      email: customer.email || '',
      dni: customer.dni || '',
      ce: customer.ce || '',
      ruc: customer.ruc || '',
      customerCode: customer.customerCode || '',
      customerType: customer.customerTypeCode,
    });

    // Set validators based on person type
    this.updateValidators();
  }

  private updateValidators(): void {
    const personType = this.form.getRawValue().personType;

    if (personType === 'NATURAL') {
      this.form.get('firstName')?.setValidators([Validators.required]);
      this.form.get('lastName')?.setValidators([Validators.required]);
      this.form.get('legalName')?.clearValidators();
    } else {
      this.form.get('legalName')?.setValidators([Validators.required]);
      this.form.get('firstName')?.clearValidators();
      this.form.get('lastName')?.clearValidators();
    }

    this.form.get('firstName')?.updateValueAndValidity();
    this.form.get('lastName')?.updateValueAndValidity();
    this.form.get('legalName')?.updateValueAndValidity();
  }

  onPersonTypeChange(): void {
    this.updateValidators();
  }

  private serializeNotes(): Record<string, string> | null {
    const notesArr = this.notesArray.value as Array<{ key: string; value: string }>;
    const notesObj: Record<string, string> = {};
    for (const { key, value } of notesArr) {
      if (key && key.trim()) notesObj[key.trim()] = value;
    }
    return Object.keys(notesObj).length ? notesObj : null;
  }

  async onSubmit(): Promise<void> {
    if (this.form.invalid) {
      this.markFormGroupTouched();
      return;
    }

    this.saving.set(true);
    this.error.set(null);
    this.success.set(false);

    const customerId = this.customer()?.id;
    if (!customerId) {
      this.error.set('ID de cliente no encontrado');
      this.saving.set(false);
      return;
    }
    
    // generateCode is already called on value changes, but we can call it once more to be safe
    this.generateCode();
    
    const formValue = this.form.value;
    const rawValue = this.form.getRawValue(); // Get raw value to include disabled fields like customerCode

    const updateData = {
      firstName: formValue.firstName || null,
      lastName: formValue.lastName || null,
      legalName: formValue.legalName || null,
      phone: formValue.phone,
      email: formValue.email || null,
      dni: formValue.dni || null,
      ce: formValue.ce || null,
      ruc: formValue.ruc || null,
      customerCode: rawValue.customerCode || null, // Use rawValue for customerCode
      customerType: formValue.customerType,
      notes: this.serializeNotes(),
    };

    // console.log('Update data:', updateData);
    console.log('Update data:', updateData);

    try {
      const updatedCustomer = await this.customerService.updateCustomer(customerId, updateData);
      this.customer.set(updatedCustomer);
      this.success.set(true);
      this.saving.set(false);

      // Clear success message after 3 seconds
      setTimeout(() => {
        this.success.set(false);
      }, 3000);
    } catch (err: any) {
      console.error('Error updating customer:', err);
      this.error.set('Error al actualizar el cliente');
      this.saving.set(false);
    }
  }

  generateCode() {
    const { firstName, lastName } = this.form.value;
    if (!firstName || !lastName) return;
    
    const code = generateCustomerCode(firstName, lastName);
    this.form.get('customerCode')?.setValue(code);
  }

  async onDelete(): Promise<void> {
    const customer = this.customer();
    if (!customer) return;

    if (
      !confirm(
        `¿Está seguro de que desea eliminar al cliente "${customer.firstName || customer.legalName}"?`,
      )
    ) {
      return;
    }

    this.deleting.set(true);
    this.deleteError.set(null);
    this.deleteSuccess.set(false);

    try {
      await this.customerService.softDeleteCustomer(customer.id);
      this.deleteSuccess.set(true);
      this.deleting.set(false);

      // Redirect to list after 2 seconds
      setTimeout(() => {
        this.router.navigate(['/clientes']);
      }, 2000);
    } catch (err: any) {
      console.error('Error deleting customer:', err);
      this.deleteError.set('Error al eliminar el cliente');
      this.deleting.set(false);
    }
  }

  private markFormGroupTouched(): void {
    Object.keys(this.form.controls).forEach((key) => {
      const control = this.form.get(key);
      control?.markAsTouched();
    });
  }
}
