import { Component, inject, signal, OnInit, computed } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { CustomersService } from '../customers-service';
import { CustomerModel } from '@core/customer-model';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-customers-list',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './customers-list.html',
  styleUrl: './customers-list.css'
})
export default class CustomersList implements OnInit {
  private customersService: CustomersService = inject(CustomersService);
  customers = signal<CustomerModel[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  deleteSuccess = signal(false);

  filter = signal<'all' | 'active' | 'inactive'>('active');
  search = signal('');
  searchValue = '';

  filteredCustomers = computed(() => {
    let list = this.customers();
    if (this.filter() === 'active') list = list.filter(c => c.isActive);
    if (this.filter() === 'inactive') list = list.filter(c => !c.isActive);
    const q = this.search().toLowerCase();
    if (q) {
      list = list.filter(c =>
        (c.fullName?.toLowerCase().includes(q) || '') ||
        (c.phone?.toLowerCase().includes(q) || '') ||
        (c.email?.toLowerCase().includes(q) || '')
      );
    }
    return list;
  });

  onSearchChange(val: string) {
    this.searchValue = val;
    this.search.set(val);
  }

  async ngOnInit() {
    this.loading.set(true);
    try {
      const data = await this.customersService.getAll();
      this.customers.set(data || []);
      this.error.set(null);
    } catch (e: any) {
      this.error.set(e.message || 'Error al cargar clientes');
    }
    this.loading.set(false);
  }
  async deleteCustomer(id: string | undefined) {
    if (!id) return;
    if (!confirm('¿Seguro que deseas eliminar este cliente?')) return;
    try {
      await this.customersService.softDelete(id);
      this.deleteSuccess.set(true);
      this.ngOnInit();
      setTimeout(() => this.deleteSuccess.set(false), 800);
    } catch (e: any) {
      alert('Error al eliminar: ' + (e.message || e));
    }
  }
}
