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
        children: [
          { path: '', loadComponent: () => import('./features/customers/list/customers-list') },
          { path: 'create', loadComponent: () => import('./features/customers/create/customers-create') },
          // { path: 'edit/:id', loadComponent: () => import('./features/customers/edit/customers-edit') },
        ]
      },
      {
        path: 'tickets',
        loadComponent: () => import('@features/tickets/tickets')
      },
      {
        path: 'configuracion',
        children: [
          { path: '', loadComponent: () => import('@features/settings/settings') },
          {
            path: 'crear_usuario',
            loadComponent: () => import('@features/auth/sign-up/sign-up')
          }
        ]
      },
      {
        path: '**',
        redirectTo: 'dashboard'
      }
    ]
  },
  {
    path: '**',
    redirectTo: 'auth',
  }

];