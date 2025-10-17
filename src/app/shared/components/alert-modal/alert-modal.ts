import { CommonModule } from '@angular/common';
import { Component, EventEmitter, HostListener, Input, Output } from '@angular/core';

@Component({
  selector: 'app-alert-modal',
  imports: [CommonModule],
  templateUrl: './alert-modal.html'
})
export class AlertModal {
  @Input() title = '';
  @Input() message = '';
  @Input() type: 'info' | 'warning' | 'error' | 'success' = 'success';

  @Output() closed = new EventEmitter<void>();

  onClose() {
    this.closed.emit();
  }

  @HostListener('document:keydown', ['$event'])
  handleEsc(event: KeyboardEvent) {
    if (event.key === 'Escape') {
      event.preventDefault();
      this.onClose();
    }
  }
}