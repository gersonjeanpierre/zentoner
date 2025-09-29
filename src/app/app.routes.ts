import { Routes } from '@angular/router';
import { authGuard, authRedirectGuard } from '@shared/guards/auth-guard';

export const routes: Routes = [

  {
    path: 'auth',
    canActivate: [authRedirectGuard],
    loadChildren: () => import('./features/auth/auth.routes')
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('@features/layout/layout'),
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('@features/dashboard/dashboard')
      },
      {
        path: 'clientes',
        loadComponent: () => import('@features/clients/clients')
      }
    ]
  },
  {
    path: '**',
    redirectTo: 'auth',
  }

];
