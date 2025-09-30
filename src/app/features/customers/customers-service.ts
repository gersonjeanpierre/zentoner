import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { CustomerModel } from '@core/customer-model';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

@Injectable({ providedIn: 'root' })
export class CustomersService {
  private supabase = inject(SupabaseService);

  async getAll() {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .select('*')
      .order('full_name', { ascending: true });
    if (error) throw error;
    return camelcaseKeys(data, { deep: true }) as CustomerModel[];
  }

  async getById(id: string) {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return camelcaseKeys(data, { deep: true }) as CustomerModel;
  }

  async create(customer: CustomerModel) {
    const snakeCustomer = snakecaseKeys(customer as Record<string, unknown>, { deep: true });
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .insert([snakeCustomer])
      .select()
      .single();
    if (error) throw error;
    return camelcaseKeys(data, { deep: true }) as CustomerModel;
  }

  async update(id: string, customer: Partial<CustomerModel>) {
    const snakeCustomer = snakecaseKeys(customer as Record<string, unknown>, { deep: true });
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .update(snakeCustomer)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return camelcaseKeys(data, { deep: true }) as CustomerModel;
  }

  async softDelete(id: string) {
    return this.update(id, { isActive: false });
  }
}