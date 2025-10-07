import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TicketData, TicketItem } from '@core/tickets';
import { TicketPreview } from './ticket-preview/ticket-preview';



@Component({
  selector: 'app-tickets',
  imports: [CommonModule, FormsModule, TicketPreview],
  templateUrl: './tickets.html',
  styleUrl: './tickets.css'
})
export default class Tickets {


  ticketData: TicketData = {
    companyName: '<-- LASER COLOR VELOZ -->',
    client: 'ROCKY BALBOA',
    designer: 'GERSON SALAS',
    creationDate: new Date(),
    saleDetails: [
      { description: 'Diseño Logo', quantity: 1, price: 150.00, total: 150.00 },
      { description: 'Impresión Tarjetas', quantity: 100, price: 0.50, total: 50.00 }
    ],
    totalPrice: 200.00,
    advance: 50.00,
    discount: 10.00,
    igv: 32.40,
    finalAmount: 222.40,
    printDate: new Date()
  };

  constructor() {
    this.calculateTotals();
  }

  printTicket(): void {
    this.ticketData.printDate = new Date();
    const preview = document.querySelector('.ticket-preview');
    if (!preview) return;

    const printWindow = window.open('', '_blank', 'width=300,height=600');
    if (!printWindow) return;

    const doc = printWindow.document;
    doc.head.innerHTML = '';
    doc.body.innerHTML = '';

    const title = doc.createElement('title');
    title.textContent = `Ticket - ${this.ticketData.companyName}`;
    doc.head.appendChild(title);

    const link = doc.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'styles.css';
    doc.head.appendChild(link);

    const style = doc.createElement('style');
    style.textContent = `
      @media print {
        @page { size: 76mm auto; margin: 0; }
        body { margin: 0; padding: 0; }
      }
      body { margin: 0; padding: 0; }
    `;
    doc.head.appendChild(style);
    doc.body.appendChild(preview.cloneNode(true));

    printWindow.focus();
    setTimeout(() => printWindow.print(), 100);
  }

  formatDate(date: Date): string {
    return date.toLocaleDateString('es-ES', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit'
    });
  }

  // Method to update ticket data (for demo purposes)
  updateTicketData(data: Partial<TicketData>): void {
    this.ticketData = { ...this.ticketData, ...data };
  }

  // Methods for managing sale details
  addSaleItem(): void {
    this.ticketData.saleDetails.push({
      description: '',
      quantity: 1,
      price: 0,
      total: 0
    });
  }

  removeSaleItem(index: number): void {
    this.ticketData.saleDetails.splice(index, 1);
    this.calculateTotals();
  }

  updateSaleItem(index: number, field: keyof TicketItem, value: string | number): void {
    const item = this.ticketData.saleDetails[index];
    if (field === 'description') {
      item[field] = value as string;
    } else if (field === 'quantity' || field === 'price') {
      const numValue = typeof value === 'string' ? parseFloat(value) || 0 : value;
      item[field] = numValue;
      item.total = item.quantity * item.price;
    } else if (field === 'total') {
      item[field] = typeof value === 'string' ? parseFloat(value) || 0 : value;
    }
    this.calculateTotals();
  }

  calculateTotals(): void {
    // Calculate total price from sale details
    this.ticketData.totalPrice = this.ticketData.saleDetails.reduce((sum, item) => sum + item.total, 0);

    // Calculate IGV (18%)
    this.ticketData.igv = this.ticketData.totalPrice * 0.18;

    // Calculate final amount (total - discount + IGV - advance)
    this.ticketData.finalAmount = this.ticketData.totalPrice - this.ticketData.discount + this.ticketData.igv - this.ticketData.advance;
  }

  // Update methods for form fields
  updateDesigner(value: string): void {
    this.ticketData.designer = value;
  }

  updateClient(value: string): void {
    this.ticketData.client = value;
  }

  updateCreationDate(value: string): void {
    this.ticketData.creationDate = new Date(value);
  }

  updateAdvance(value: number): void {
    this.ticketData.advance = value || 0;
    this.calculateTotals();
  }

  updateDiscount(value: number): void {
    this.ticketData.discount = value || 0;
    this.calculateTotals();
  }
}
