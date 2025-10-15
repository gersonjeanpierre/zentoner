import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import SignUp from '@features/auth/sign-up/sign-up';

@Component({
  selector: 'app-settings',
  imports: [SignUp],
  templateUrl: './settings.html',
  styleUrl: './settings.css'
})
export default class Settings {

}
