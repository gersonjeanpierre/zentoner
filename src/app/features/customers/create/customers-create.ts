import { Component, inject, signal } from '@angular/core';
import { FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { CustomersService } from '../customers-service';
import { CustomerPayload } from '@core/customer/customer-model';
import { v7 as uuidv7 } from 'uuid';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-customers-create',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './customers-create.html',
  styleUrl: './customers-create.css'
})
export default class CustomersCreate {
  addNote() {
    this.notesArray.push(this.fb.group({ key: [''], value: [''] }));
  }

  removeNote(i: number) {
    this.notesArray.removeAt(i);
  }
  private fb = inject(FormBuilder);
  private customersService = inject(CustomersService);
  private router = inject(Router);

  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);

  form = this.fb.group({
    firstName: ['', [Validators.required]],
    lastName: ['', [Validators.required]],
    legalName: [''],
    email: ['', [Validators.email]],
    phone: ['', [Validators.required]],
    dni: [''],
    ruc: [''],
    ce: [''],
    personType: [''],
    customerCode: [''],
    customerType: [''],
    notes: this.fb.array([])
  });

  get notesArray() {
    return this.form.get('notes') as import('@angular/forms').FormArray;
  }


  async onSubmit() {

    if (this.form.invalid) return;
    this.loading.set(true);
    this.error.set(null);
    const raw = this.form.value;
    // Ajusta los valores para que coincidan con el modelo
    // Serializa notes FormArray a objeto clave/valor
    const notesArr = this.notesArray.value as Array<{ key: string; value: string }>;
    const notesObj: Record<string, string> = {};
    for (const n of notesArr) {
      if (n.key && n.key.trim()) notesObj[n.key.trim()] = n.value;
    }
    const customer: CustomerPayload = {
      id: uuidv7(),
      firstName: raw.firstName ?? '',
      lastName: raw.lastName ?? '',
      legalName: raw.legalName || null,
      email: raw.email || null,
      phone: raw.phone || null,
      dni: raw.dni || null,
      ruc: raw.ruc || null,
      ce: raw.ce || null,
      personType: (raw.personType || '').toLowerCase() as 'juridico' | 'natural',
      customerCode: raw.customerCode || null,
      customerType: (raw.customerType || '').toLowerCase() as 'nuevo' | 'frecuente' | 'imprentero_nuevo' | 'imprentero_frecuente',
      notes: Object.keys(notesObj).length ? notesObj : null
    };
    try {
      await this.customersService.upsertCustomer(customer);
      this.success.set(true);
      setTimeout(() => this.router.navigate(['/clientes']), 800);
    } catch (e: any) {
      this.error.set(e.message || 'Error al crear cliente');
    }
    this.loading.set(false);
  }
}
