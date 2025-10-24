import { Component, inject, signal, OnInit } from '@angular/core';
import { Router, RouterLink, RouterOutlet, NavigationEnd, ActivatedRoute } from '@angular/router';
import { AuthService } from '@features/auth/auth-service';
import { LogoLaserVeloz } from '@shared/components/logo-laser-veloz/logo-laser-veloz';
import { CommonModule } from '@angular/common';
import { filter } from 'rxjs';
import { Breadcrumb } from '@core/layout/breadcrumb-model';

@Component({
  selector: 'app-layout',
  imports: [LogoLaserVeloz, RouterLink, RouterOutlet, CommonModule, RouterOutlet],
  templateUrl: './layout.html',
  styleUrl: './layout.css'
})
export default class Layout implements OnInit {
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  user = signal<any | null>(null);
  session = signal<any | null>(null);

  activeMenu = signal('Dashboard');
  fontSize = signal('1.2em');

  breadcrumbs = signal<Array<{ label: string; routeLink: string, icon: string }>>([]);

  constructor() {
    this.router.events.pipe(
      filter(event => event instanceof NavigationEnd)
    ).subscribe(() => {
      this.breadcrumbs.set(this.buildBreadcrumbs(this.route.root));
    }
    )
  }

  buildBreadcrumbs(
    route: ActivatedRoute,
    url: string = '',
    breadcrumbs: Breadcrumb[] = []
  ): Breadcrumb[] {
    const children = route.children;

    if (children.length === 0) {
      return breadcrumbs;
    }

    for (const child of children) {
      // Obtén el segmento de la URL actual
      const segment = child.snapshot.url.map(s => s.path).join('/');
      const nextUrl = segment ? `${url}/${segment}` : url;

      // Obtén el label y el icono desde los datos de la ruta
      const label = child.snapshot.data['breadcrumb'] || segment;
      const icon = child.snapshot.data['icon'] || '';

      // Si hay label, agrega el breadcrumb
      if (label) {
        breadcrumbs.push({ label, routeLink: nextUrl, icon });
      }

      // Recursividad para los hijos
      return this.buildBreadcrumbs(child, nextUrl, breadcrumbs);
    }

    return breadcrumbs;
  }

  menuItems = [
    {
      name: 'Dashboard',
      icon: 'icon-[fa7-solid--layer-group]',
      routeLink: '/dashboard'
    },
    {
      name: 'Clientes',
      icon: 'icon-[fa6-solid--users]',
      routeLink: '/clientes'
    },
    {
      name: 'Ventas',
      icon: 'icon-[fa7-solid--file-invoice-dollar]',
      routeLink: '/ventas'
    },
    {
      name: 'Inventario',
      icon: 'icon-[fa7-solid--boxes]',
      routeLink: '/inventario'
    },
    {
      name: 'Reportes',
      icon: 'icon-[fa6-solid--chart-line]',
      routeLink: '/reportes'
    },
    {
      name: 'Tickets',
      icon: 'icon-[fa6-solid--ticket]',
      routeLink: '/tickets'
    },
    {
      name: 'Configuración',
      icon: 'icon-[fa6-solid--gear]',
      routeLink: '/configuracion'
    },
    {
      name: 'Cerrar sesión',
      icon: 'icon-[fa7-solid--sign-out-alt]',
      routeLink: '/auth/log-in'
    }
  ]


  async ngOnInit() {
    // Obtener usuario y sesión activa de Supabase
    try {
      const userRes = await this.authService.getUser();
      this.user.set(userRes.data?.user || null);
      const sessionRes = await this.authService.getSession();
      this.session.set(sessionRes.data.session?.user.role || null);
    } catch (e) {
      this.user.set(null);
      this.session.set(null);
    }

    // Set active menu based on current route
    this.setActiveMenuByRoute(this.router.url);

    // Listen to route changes
    this.router.events.subscribe((event) => {
      if (event instanceof NavigationEnd) {
        this.setActiveMenuByRoute(event.urlAfterRedirects);
      }
    });
  }

  setActiveMenuByRoute(url: string) {
    // Find the menu item whose routeLink matches the start of the url
    const found = this.menuItems.find(item => url.startsWith(item.routeLink));
    if (found) {
      this.activeMenu.set(found.name);
    }
  }

  logOut() {
    this.activeMenu.set('Cerrar sesión');
    this.authService.signOut();
    this.router.navigateByUrl('/auth/log-in');
  }
}
