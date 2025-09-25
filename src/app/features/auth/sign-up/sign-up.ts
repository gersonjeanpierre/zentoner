import { Component, inject } from '@angular/core';
import { LogoLaserVeloz } from '../../../shared/components/logo-laser-veloz/logo-laser-veloz';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { SignUpForm } from '@core/auth/sign-up.interface';
import { AuthService } from '../auth-service';

@Component({
  selector: 'app-sign-up',
  imports: [LogoLaserVeloz, ReactiveFormsModule],
  templateUrl: './sign-up.html',
  styleUrl: './sign-up.css'
})
export default class SignUp {

  private fb = inject(FormBuilder)
  private authService = inject(AuthService)

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
    ])
  })

  async onSubmit() {
    if (this.signUpForm.invalid) return;
    const authResponse = await this.authService.signUp({
      email: this.signUpForm.value.email ?? '',
      password: this.signUpForm.value.password ?? ''
    })
    console.log({ authResponse })

  }

}
