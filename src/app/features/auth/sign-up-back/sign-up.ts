import { Component, inject, signal } from '@angular/core';
import { LogoLaserVeloz } from '../../../shared/components/logo-laser-veloz/logo-laser-veloz';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { SignUpForm } from '@core/auth/sign-up-model';
import { AuthService } from '../auth-service';
import { AlertModal } from '@shared/components/alert-modal/alert-modal';
import { TranslateService } from '@ngx-translate/core';
import { NgClass } from '@angular/common';

@Component({
  selector: 'app-sign-up',
  imports: [LogoLaserVeloz, ReactiveFormsModule, AlertModal, NgClass],
  templateUrl: './sign-up.html',
})
export default class SignUpBack {

  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private translate = inject(TranslateService);

  // Modal de alerta
  isLoading = signal(false);
  showAlertModal = signal(false);
  alertMessage = signal('');
  alertTitle = signal('');
  showModal = signal(false);
  alertType = signal<'info' | 'warning' | 'error' | 'success'>('success');

  signUpForm = this.fb.group<SignUpForm>({
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
    ]),
    firstName: this.fb.control(null, [
      Validators.required,
      Validators.minLength(2),
      Validators.maxLength(35),
    ]),
    lastName: this.fb.control(null, [
      Validators.required,
      Validators.minLength(2),
      Validators.maxLength(80),
    ]),
    selectedRoles: this.fb.control([], Validators.required)
  })

  async onSubmit() {
    if (this.signUpForm.invalid) return;
    this.isLoading.set(true);
    const { data, error } = await this.authService.signUp({
      email: this.signUpForm.value.email ?? '',
      password: this.signUpForm.value.password ?? '',
      options: {
        data: {
          first_name: this.signUpForm.value.firstName ?? '',
          last_name: this.signUpForm.value.lastName ?? '',
        }
      }
    });
    console.log({ data, error });
    this.isLoading.set(false);
    if (error) {
      this.showAlert(
        '¡Error al registrar!',
        this.getErrorTranslation(error.message),
        'error'
      )
      return;
    }
    this.showAlert(
      '¡Registro exitoso!',
      'La cuenta del empleado ha sido creada exitosamente.',
      'success'
    );
    this.signUpForm.reset();
  }

  private showAlert(title: string, message: string, type: 'info' | 'warning' | 'error' | 'success') {
    this.showModal.set(true);
    this.alertTitle.set(title);
    this.alertMessage.set(message);
    this.alertType.set(type);
  }

  private getErrorTranslation(message: string): string {
    // Busca la traducción exacta, si no existe usa el genérico
    return this.translate.instant(`auth.errors.${message}`) || this.translate.instant('auth.errors.generic');
  }
}