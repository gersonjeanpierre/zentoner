import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-layout',
  imports: [],
  templateUrl: './layout.html',
  styleUrl: './layout.css'
})
export default class Layout {

  activeMenu = signal('Dashboard');

  setActiveMenuLink(menu: string) {
    this.activeMenu.set(menu);
  }
}
