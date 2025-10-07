import { Component, Input } from '@angular/core';
import { TicketData } from '@core/tickets';

@Component({
  selector: 'app-ticket-preview',
  imports: [],
  templateUrl: './ticket-preview.html',
  styleUrl: './ticket-preview.css'
})
export class TicketPreview {
  @Input() ticketData!: TicketData;
  @Input() printDate!: Date;

  formatDate(date: Date): string {
    const format = date.toLocaleDateString('es-PE', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    });
    return format.replace(',', '');
  }
}
