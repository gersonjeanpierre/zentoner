import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { CustomerPayload, CustomerView, ReturnListCustomers } from '@core/customer/customer-model';

@Injectable({ providedIn: 'root' })
export class CustomerService {
  private supabase = inject(SupabaseService).supabaseClient;
  private salesCustomersTable = { schema: 'sales', table: 'customers' };

  async createCustomer(payload: CustomerPayload) {
    if (payload.dni && payload.ce) {
      throw new Error("No se puede tener ambos campos 'dni' y 'ce' al mismo tiempo.");
    }

    const { data, error } = await this.supabase
      .schema(this.salesCustomersTable.schema)
      .rpc('create_customer', {
        p_user_id: payload.id,
        p_first_name: payload.firstName,
        p_last_name: payload.lastName,
        p_legal_name: payload.legalName,
        p_email: payload.email,
        p_phone: payload.phone,
        p_dni: payload.dni,
        p_ruc: payload.ruc,
        p_ce: payload.ce,
        p_person_type: payload.personType,
        p_customer_code: payload.customerCode,
        p_customer_type_code: payload.customerType,
        p_notes: payload.notes,
      });

    if (error) throw error.message || error;

    return data.id as string;
  }

  async viewCustomers() {
    const { data, error } = await this.supabase
      .schema(this.salesCustomersTable.schema)
      .from('active_customers')
      .select('*');
    console.log('Supabase response:', { data, error });
    if (error) throw error.message || error;
    return data;
  }
}
