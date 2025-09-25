import { Routes } from '@angular/router';

export const routes: Routes = [

  {
    path: 'auth',
    loadChildren: () => import('./features/auth/auth.routes')
  },
  {
    path: 'clientes',
    loadComponent: () => import('./features/clients/clients')
  },
  {
    path: 'layout',
    loadComponent: () => import('./features/layout/layout')
  }


];
