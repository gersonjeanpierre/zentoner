import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

interface TicketItem {
  description: string;
  quantity: number;
  price: number;
  total: number;
}

interface TicketData {
  companyName: string;
  designer: string;
  client: string;
  creationDate: Date;
  saleDetails: TicketItem[];
  totalPrice: number;
  advance: number;
  discount: number;
  igv: number;
  finalAmount: number;
  printDate: Date;
}

@Component({
  selector: 'app-tickets',
  imports: [CommonModule, FormsModule],
  templateUrl: './tickets.html',
  styleUrl: './tickets.css'
})
export default class Tickets {
  ticketData: TicketData = {
    companyName: 'LASER COLOR VELOZ',
    designer: 'GERSON SALAS',
    client: 'ROCKY BALBOA',
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
    // Update print date
    this.ticketData.printDate = new Date();

    const printWindow = window.open('', '_blank', 'width=300,height=600');
    if (printWindow) {
      printWindow.document.write(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Ticket - ${this.ticketData.companyName}</title>
          <style>
            @media print {
              @page {
                size: 76mm auto;
                margin: 0;
              }
              body {
                margin: 0;
                padding: 0;
              }
            }
            body {
              font-family: 'JetBrainsNFMono', monospace;
              font-size: 14px;
              line-height: 1.5;
              margin: 0 auto;
              padding: 3mm 4mm;
              box-sizing: border-box;
              -webkit-font-smoothing: none;
              font-smooth: never;
            }
            .ticket {
              width: 100%;
              text-align: center;
            }
            .header {
              font-weight: bold;
              font-size: 13px;
              margin-bottom: 6px;
            }
            .divider {
              border-top: 1px dashed #000;
              margin: 6px 0;
            }
            .row {
              display: flex;
              justify-content: space-between;
              margin: 2px 0;
              font-size: 12px;
            }
            .label {
              font-weight: bold;
            }
            .total {
              font-weight: bold;
              font-size: 12px;
              border-top: 1px solid #000;
              padding-top: 4px;
              margin-top: 4px;
            }
            .footer {
              margin-top: 8px;
              font-size: 12px;
            }
          </style>
        </head>
        <body>
          <div class="ticket">
            <div class="header">${this.ticketData.companyName}</div>
            <div class="divider"></div>

            <div class="row">
              <span class="label">Diseñador:</span>
              <span>${this.ticketData.designer || 'N/A'}</span>
            </div>

            <div class="row">
              <span class="label">Cliente:</span>
              <span>${this.ticketData.client || 'N/A'}</span>
            </div>

            <div class="row">
              <span class="label">Fecha Creación:</span>
              <span>${this.formatDate(this.ticketData.creationDate)}</span>
            </div>

            <div class="divider"></div>

            <div class="label">Detalle de Venta:</div>
            ${this.ticketData.saleDetails.map(item => `
              <div class="row">
                <span>${item.description || 'Sin descripción'}</span>
                <span>x${item.quantity}</span>
              </div>
              <div class="row">
                <span>S/ ${item.price.toFixed(2)}</span>
                <span>S/ ${item.total.toFixed(2)}</span>
              </div>
            `).join('')}

            <div class="divider"></div>

            <div class="row">
              <span class="label">Precio Total:</span>
              <span>S/ ${this.ticketData.totalPrice.toFixed(2)}</span>
            </div>

            <div class="row">
              <span class="label">Adelanto:</span>
              <span>S/ ${this.ticketData.advance.toFixed(2)}</span>
            </div>

            <div class="row">
              <span class="label">Descuento:</span>
              <span>S/ ${this.ticketData.discount.toFixed(2)}</span>
            </div>

            <div class="row">
              <span class="label">IGV (18%):</span>
              <span>S/ ${this.ticketData.igv.toFixed(2)}</span>
            </div>

            <div class="row total">
              <span>Monto Final:</span>
              <span>S/ ${this.ticketData.finalAmount.toFixed(2)}</span>
            </div>

            <div class="divider"></div>

            <div class="footer">
              Fecha de Impresión: ${this.formatDate(this.ticketData.printDate)}
            </div>
          </div>
        </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.focus();
      // Small delay to ensure content is loaded before printing
      setTimeout(() => {
        printWindow.print();
      }, 100);
    }
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
