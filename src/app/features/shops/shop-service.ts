import { inject, Injectable } from '@angular/core';
import { ReturnListShops, ShopModel } from '@core/shop/shop-model';
import { SupabaseService } from '@shared/data-acces/supabase-service';

@Injectable({
  providedIn: 'root',
})
export class ShopService {
  private readonly supabase = inject(SupabaseService).supabaseClient;

  /**
   * Lista tiendas con filtros opcionales.
   * @param filters Filtros opcionales.
   */
  async listShops(filters?: Partial<ShopModel>): Promise<ReturnListShops> {
    let query = this.supabase.rpc('rpc_get_shops_for_user');
    // Filtros dinámicos
    if (filters) {
      if (filters.createdById) {
        query = query.eq('created_by_id', filters.createdById);
      }
      if (filters.deletedAt === null) {
        query = query.is('deleted_at', null);
      }
    }

    const { data, error } = await query;
    return {
      data: (data as ShopModel[]) ?? undefined,
      error: error ?? undefined,
    };
  }

  /**
   * Obtener los detalles de todas las tiendas.
   * @return Detalles de las tiendas o error.
   * @param filters Filtros opcionales.
   */
  async getShopDetails(filters?: Partial<ShopModel>): Promise<ReturnListShops> {
    let query = this.supabase.schema('core').from('shops').select('*');
    // Filtros dinámicos
    if (filters) {
      if (filters.id) {
        query = query.eq('id', filters.id);
      }
      if (filters.createdById) {
        query = query.eq('created_by_id', filters.createdById);
      }
      if (filters.deletedAt === null) {
        query = query.is('deleted_at', null);
      }
    }

    const { data, error } = await query;
    return {
      data: (data as ShopModel[]) ?? undefined,
      error: error ?? undefined,
    };
  }
}
