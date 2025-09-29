import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { CustomerModel } from '@core/customer-model';

@Injectable({ providedIn: 'root' })
export class CustomersService {
  private supabase = inject(SupabaseService);

  async getAll() {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .select('*')
      .order('fullName', { ascending: true });
    if (error) throw error;
    return data as CustomerModel[];
  }

  async getById(id: string) {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data as CustomerModel;
  }

  async create(customer: CustomerModel) {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .insert([customer])
      .select()
      .single();
    if (error) throw error;
    return data as CustomerModel;
  }

  async update(id: string, customer: Partial<CustomerModel>) {
    const { data, error } = await this.supabase.supabaseClient
      .from('customers')
      .update(customer)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data as CustomerModel;
  }

  async softDelete(id: string) {
    return this.update(id, { isActive: false });
  }
}
