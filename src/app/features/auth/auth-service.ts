import { HttpClient } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import { EdgeFunctionPayload } from '@core/auth/edge-function-payload-model';
import { EdgeFunctionResponse } from '@core/auth/edge-function-response-model';
import { environment } from '@env/environment';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { SignUpWithPasswordCredentials } from '@supabase/supabase-js';
import { firstValueFrom } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private authSupabaseClient = inject(SupabaseService).supabaseClient;
  private http = inject(HttpClient);
  private edgeFunctionUrl = `${environment.SUPABASE_URL}/functions/v1/create-employee`;

  // Método de registro seguro para EMPLEADOS (Usa Edge Function)
  async registerEmployeeSecurely(payload: EdgeFunctionPayload): Promise<EdgeFunctionResponse> {
    // 1. Obtener la sesión y el token del USUARIO LOGUEADO (el Administrador/Creador)
    const {
      data: { session },
      error: sessionError,
    } = await this.authSupabaseClient.auth.getSession();

    if (sessionError || !session) {
      // Si no hay sesión, lanzamos un error de autenticación
      throw new Error('AUTH_REQUIRED');
    }

    const token = session.access_token;

    // 2. Preparar headers con el token JWT
    const headers = {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    };

    try {
      // 3. Llamada HTTP a la Edge Function
      const response = await firstValueFrom(
        this.http.post<EdgeFunctionResponse>(this.edgeFunctionUrl, payload, { headers }),
      );

      return response;
    } catch (httpError: any) {
      // El error de la Edge Function (403, 500) se atrapa aquí
      const serverError = httpError.error || {
        error: 'Error de red o Edge Function no disponible.',
      };
      console.error('Error del servidor:', serverError);

      // La Edge Function devuelve el error en el cuerpo 'error'
      throw new Error(serverError.error || 'GENERIC_SERVER_ERROR');
    }
  }

  signUp(credentials: SignUpWithPasswordCredentials) {
    return this.authSupabaseClient.auth.signUp(credentials);
  }

  logIn(credentials: SignUpWithPasswordCredentials) {
    return this.authSupabaseClient.auth.signInWithPassword(credentials);
  }

  signOut() {
    return this.authSupabaseClient.auth.signOut();
  }

  getUser() {
    return this.authSupabaseClient.auth.getUser();
  }

  getSession() {
    return this.authSupabaseClient.auth.getSession();
  }

  async isAuthManagementAvailable() {
    console.log(
      ' Get USer',
      await this.authSupabaseClient.auth.getUser().then((u) => u.data.user?.id || ''),
    );
    return this.authSupabaseClient.schema('auth_management').rpc('is_universal_manager', {
      user_id: await this.authSupabaseClient.auth.getUser().then((u) => u.data.user?.id || ''),
    });
  }
}
