import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-alert-modal',
  imports: [CommonModule],
  templateUrl: './alert-modal.html'
})
export class AlertModal {
  @Input() title = '';
  @Input() message = '';
  @Input() show: boolean = false;
  @Input() type: 'info' | 'warning' | 'error' | 'success' = 'success';

  @Output() closed = new EventEmitter<void>();

  close() {

    this.closed.emit();
  }
}