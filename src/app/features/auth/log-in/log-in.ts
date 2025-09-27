import { Component, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { LogoLaserVeloz } from '@shared/components/logo-laser-veloz/logo-laser-veloz';
import { AuthService } from '../auth-service';
import { SignUpForm as LogInForm } from '@core/auth/sign-up.interface';

@Component({
  selector: 'app-log-in',
  imports: [LogoLaserVeloz, ReactiveFormsModule],
  templateUrl: './log-in.html',
  styleUrl: './log-in.css'
})
export default class LogIn {

  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  logInForm = this.fb.group<LogInForm>({
    email: this.fb.control(null, [
      Validators.required,
      Validators.email,
      Validators.minLength(6),
      Validators.maxLength(40),
    ]),
    password: this.fb.control(null, [
      Validators.required,
      Validators.minLength(6),
      Validators.maxLength(20),
    ])
  })

  async onSubmit() {
    if (this.logInForm.invalid) return;

    try {
      const { data } = await this.authService.logIn({
        email: this.logInForm.value.email ?? '',
        password: this.logInForm.value.password ?? ''
      });

      this.router.navigateByUrl('/layout');

    } catch (error) {
      console.error({ error });
    }

  }

}
