import { Component, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '@features/auth/auth-service';

@Component({
  selector: 'app-layout',
  imports: [],
  templateUrl: './layout.html',
  styleUrl: './layout.css'
})
export default class Layout {

  private authService = inject(AuthService);
  private router = inject(Router);

  activeMenu = signal('Dashboard');

  setActiveMenuLink(menu: string) {
    this.activeMenu.set(menu);
  }

  logOut() {
    this.authService.signOut();
    this.router.navigateByUrl('/auth/log-in');
  }
}
