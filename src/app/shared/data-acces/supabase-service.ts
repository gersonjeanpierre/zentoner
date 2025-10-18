import { Injectable } from '@angular/core';
import { RoleModel } from '@core/auth/role-model';
import { environment } from '@env/environment';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable({
  providedIn: 'root'
})
export class SupabaseService {

  supabaseClient: SupabaseClient;

  constructor() {
    if (!environment.SUPABASE_URL || !environment.SUPABASE_KEY) {
      throw new Error('Las claves de Supabase no están definidas en las variables de entorno.');
    }
    this.supabaseClient = createClient(
      environment.SUPABASE_URL,
      environment.SUPABASE_KEY
    )
  }

  // Nuevo método para obtener todos los roles disponibles (SELECT permitido por RLS)
  async getAvailableRoles(): Promise<RoleModel[]> {
    const { data, error } = await this.supabaseClient
      .from('roles')
      .select('id, name')
      .order('name', { ascending: true }); // Ordenar alfabéticamente

    if (error) {
      console.error('Error al obtener roles:', error);
      throw new Error('Fallo al cargar la lista de roles.');
    }

    return data as RoleModel[];
  }
}