import { Injectable, inject } from '@angular/core';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { CustomerPayload, CustomerView } from '@core/customer/customer-model';
import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';

@Injectable({ providedIn: 'root' })
export class CustomerService {
  private supabase = inject(SupabaseService).supabaseClient;

  /**
   * Realiza el borrado lógico de un cliente usando la función RPC 'soft_delete_customer'.
   * @param customerId El UUID del cliente a eliminar.
   */
  async softDelete(customerId: string): Promise<void> {
    const { error } = await this.supabase.rpc('soft_delete_customer', { p_id: customerId });
    if (error) {
      console.error('Error al eliminar customer:', error);
      throw new Error(error.message);
    }
  }

  /**
   * Crea o actualiza un cliente llamando a la función RPC 'upsert_customer'.
   * @param payload Los datos del cliente.
   * @returns El UUID del cliente.
   */
  async upsertCustomer(payload: CustomerPayload): Promise<string> {
    const { data, error } = await this.supabase.rpc('upsert_customer', {
      p_id: payload.id,
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
      p_customer_type: payload.customerType,
      p_notes: payload.notes,
    });

    if (error) {
      console.error('Error al crear/actualizar customer:', error);
      throw new Error(error.message);
    }

    return data; // Retorna el UUID
  }

  /**
   * Obtiene la lista de clientes activos de la vista 'customers_active'.
   */
  async getActiveCustomers(): Promise<CustomerView[]> {
    const { data, error } = await this.supabase
      .from('customers_active')
      .select('*');

    console.log('DATA CUSTOMERS ACTIVE:', data);

    if (error) {
      console.error('Error al listar customers:', error);
      throw new Error(error.message);
    }

    // La RLS en la vista asegura que solo vea lo que debe ver.
    return data as CustomerView[];
  }

  /**
   * Obtiene un cliente activo por su ID desde la vista 'customers_active'.
   * @param customerId El UUID del cliente.
   * @returns El cliente si existe y está activo, null si no.
   */
  async getCustomerById(customerId: string): Promise<CustomerView | null> {
    const { data, error } = await this.supabase
      .from('customers_active')
      .select('*')
      .eq('id', customerId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') { // No rows returned
        return null;
      }
      console.error('Error al obtener customer por ID:', error);
      throw new Error(error.message);
    }

    return data as CustomerView;
  }

}