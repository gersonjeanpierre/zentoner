import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';


@Component({
  selector: 'app-logo-laser-veloz',
  imports: [CommonModule],
  templateUrl: './logo-laser-veloz.html',
  styleUrl: './logo-laser-veloz.css'
})
export class LogoLaserVeloz {

  @Input() fontSize: string = ''

}
