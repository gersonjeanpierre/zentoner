import { Component, inject, signal } from '@angular/core';
import { FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import { CustomersService } from '../customers-service';
import { CustomerModel } from '@core/customer-model';
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
  private fb = inject(FormBuilder);
  private customersService = inject(CustomersService);
  private router = inject(Router);

  loading = signal(false);
  error = signal<string | null>(null);
  success = signal(false);

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

  async onSubmit() {
    console.log('onSubmit called', this.form.value, this.form.valid);
    // if (this.form.invalid) {
    //   this.error.set('Formulario inválido');
    //   return;
    // }
    this.loading.set(true);
    this.error.set(null);
    const customer: CustomerModel = {
      id: uuidv7(),
      ...this.form.value,
      isActive: !!this.form.value.isActive
    };
    try {
      const result = await (this.customersService.create(customer) as Promise<CustomerModel>);
      console.log('Cliente creado:', result);
      this.success.set(true);
      this.form.reset({ isActive: true });
      setTimeout(() => this.router.navigate(['/customers']), 1200);
    } catch (e: any) {
      console.error('Error al crear cliente', e);
      this.error.set(e.message || 'Error al crear cliente');
    }
    this.loading.set(false);
  }
}
