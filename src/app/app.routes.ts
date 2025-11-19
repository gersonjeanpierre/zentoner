import { Routes } from '@angular/router';
import { authGuard, authRedirectGuard } from '@shared/guards/auth-guard';

export const routes: Routes = [
  {
    path: 'auth',
    canActivate: [authRedirectGuard],
    loadChildren: () => import('./features/auth/auth.routes'),
  },
  {
    path: '',
    canActivate: [authGuard],
    loadComponent: () => import('@features/layout/layout'),
    children: [
      {
        path: 'dashboard',
        loadComponent: () => import('@features/dashboard/dashboard'),
        data: { breadcrumb: 'Dashboard', icon: 'icon-[fa7-solid--layer-group]' },
      },
      {
        path: 'clientes',
        children: [
          {
            path: '',
            loadComponent: () => import('./features/customers/list/customers-list'),
          },
          {
            path: 'create',
            loadComponent: () => import('./features/customers/create/customers-create'),
          },
          {
            path: 'edit/:id',
            loadComponent: () =>
              import('./features/customers/edit/customers-edit').then(
                (m) => m.CustomersEditComponent,
              ),
          },
        ],
      },
      {
        path: 'tickets',
        data: { breadcrumb: 'Tickets', icon: 'icon-[fa7-solid--ticket]' },
        loadComponent: () => import('@features/tickets/tickets'),
      },
      {
        path: 'configuracion',
        data: { breadcrumb: 'Configuración', icon: 'icon-[fa7-solid--cog]' },
        children: [
          {
            path: '',
            loadComponent: () => import('@features/settings/settings'),
          },
          {
            path: 'crear_usuario',
            loadComponent: () => import('@features/auth/sign-up/sign-up'),
            data: { breadcrumb: 'Crear Usuario', icon: 'icon-[fa7-solid--user-plus]' },
          },
          {
            path: 'tiendas',
            loadComponent: () => import('@features/shops/shops'),
            data: { breadcrumb: 'Tiendas', icon: 'icon-[fa7-solid--store]' },
          },
        ],
      },
      {
        path: '**',
        redirectTo: 'dashboard',
      },
    ],
  },
  {
    path: '**',
    redirectTo: 'auth',
  },
];
