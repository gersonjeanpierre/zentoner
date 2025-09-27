import { Routes } from '@angular/router';
import { authGuard, authRedirectGuard } from '@shared/guards/auth-guard';

export const routes: Routes = [

  {
    path: 'auth',
    canActivate: [authRedirectGuard],
    loadChildren: () => import('./features/auth/auth.routes')
  },
  {
    path: 'clientes',
    canActivate: [authGuard],
    loadComponent: () => import('./features/clients/clients')
  },
  {
    path: 'layout',
    canActivate: [authGuard],
    loadComponent: () => import('./features/layout/layout')
  },
  {
    path: '**',
    redirectTo: 'auth',
  }

];
