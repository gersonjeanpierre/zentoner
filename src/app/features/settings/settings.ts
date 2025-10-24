import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import SignUp from '@features/auth/sign-up/sign-up';

@Component({
  selector: 'app-settings',
  imports: [],
  templateUrl: './settings.html',
})
export default class Settings {
  private router = inject(Router)

  toCreateUser() {
    this.router.navigate(['configuracion/crear_usuario']);
  }
}
