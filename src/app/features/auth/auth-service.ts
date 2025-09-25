import { inject, Injectable } from '@angular/core';
import { SupabaseService } from '@shared/data-acces/supabase-service';
import { SignUpWithPasswordCredentials } from '@supabase/supabase-js';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private authSupabaseClient = inject(SupabaseService).supabaseClient;

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
}
