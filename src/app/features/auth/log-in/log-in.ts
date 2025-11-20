import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { LogoLaserVeloz } from '@shared/components/logo-laser-veloz/logo-laser-veloz';
import { AuthService } from '../auth-service';
import { SignUpForm as LogInForm } from '@core/auth/sign-up-model';
import { AlertModal } from '@shared/components/alert-modal/alert-modal';

@Component({
  selector: 'app-log-in',
  imports: [LogoLaserVeloz, ReactiveFormsModule, AlertModal],
  templateUrl: './log-in.html',
  styleUrl: './log-in.css',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export default class LogIn {

  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private router = inject(Router);

  showAlert = signal(false);
  alertTitle = signal('');
  alertMessage = signal('');
  alertType = signal<'info' | 'warning' | 'error' | 'success'>('info');

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
    
    const { error } = await this.authService.logIn({
      email: this.logInForm.value.email ?? '',
      password: this.logInForm.value.password ?? ''
    });

    if (error) {
      console.error('Error en login:', error);
      this.alertTitle.set('Error al iniciar sesión');
      this.alertMessage.set(error.message);
      this.alertType.set('error');
      this.showAlert.set(true);
      return;
    }

    this.router.navigateByUrl('/');
  }

  closeAlert() {
    this.showAlert.set(false);
  }

}
