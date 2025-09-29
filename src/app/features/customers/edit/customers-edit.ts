import { Component, inject, signal, OnInit } from '@angular/core';
import { FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { CustomersService } from '../customers-service';
import { CustomerModel } from '@core/customer-model';
import { ActivatedRoute, Router } from '@angular/router';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-customers-edit',
  standalone: true,
  imports: [ReactiveFormsModule, CommonModule],
  templateUrl: './customers-edit.html',
  styleUrl: './customers-edit.css'
})
export default class CustomersEdit implements OnInit {
  private fb = inject(FormBuilder);
  private customersService = inject(CustomersService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);

  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);
  deleteSuccess = signal(false);
  deleteError = signal<string | null>(null);
  deleting = signal(false);

  form = this.fb.group({
    typePerson: [''],
    typeClient: [''],
    phone: ['', [Validators.required]],
    fullName: ['', [Validators.required]],
    socialReason: [''],
    dni: [''],
    ruc: [''],
    ce: [''],
    email: ['', [Validators.email]],
    isActive: [true]
  });

  async ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.error.set('ID de cliente no válido');
      return;
    }
    this.loading.set(true);
    try {
      const data = await (this.customersService.getById(id) as Promise<CustomerModel>);
      this.form.patchValue(data);
      this.error.set(null);
    } catch (e: any) {
      this.error.set(e.message || 'Error al cargar cliente');
    }
    this.loading.set(false);
  }

  async onSubmit() {
    if (this.form.invalid) return;
    this.loading.set(true);
    this.error.set(null);
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.error.set('ID de cliente no válido');
      return;
    }
    const customer: CustomerModel = {
      ...this.form.value,
      isActive: !!this.form.value.isActive
    };
    try {
      await (this.customersService.update(id, customer) as Promise<CustomerModel>);
      this.success.set(true);
      setTimeout(() => this.router.navigate(['/customers']), 1200);
    } catch (e: any) {
      this.error.set(e.message || 'Error al actualizar cliente');
    }
    this.loading.set(false);
  }

  async onDelete() {
    if (!confirm('¿Seguro que deseas eliminar este cliente?')) return;
    this.deleting.set(true);
    this.deleteError.set(null);
    const id = this.route.snapshot.paramMap.get('id');
    if (!id) {
      this.deleteError.set('ID de cliente no válido');
      return;
    }
    try {
      await (this.customersService.softDelete(id) as Promise<CustomerModel>);
      this.deleteSuccess.set(true);
      setTimeout(() => this.router.navigate(['/customers']), 1200);
    } catch (e: any) {
      this.deleteError.set(e.message || 'Error al eliminar cliente');
    }
    this.deleting.set(false);
  }
}
