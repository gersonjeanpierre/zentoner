import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { LogoLaserVeloz } from '../../../shared/components/logo-laser-veloz/logo-laser-veloz';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { SignUpForm } from '@core/auth/sign-up-model';
import { AuthService } from '../auth-service';
import { AlertModal } from '@shared/components/alert-modal/alert-modal';
import { TranslateService } from '@ngx-translate/core';
import { rolesUser } from '@shared/mockup';
import { ShopService } from '@features/shops/shop-service';

type RoleType = { name: string; label: string };

@Component({
  selector: 'app-sign-up',
  imports: [LogoLaserVeloz, ReactiveFormsModule, AlertModal],
  templateUrl: './sign-up.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export default class SignUp {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);
  private translate = inject(TranslateService);
  private shopService = inject(ShopService);

  availableShops = signal<{ id: string; name: string }[]>([]);

  // Modal de alerta
  isLoading = signal(false);
  alertMessage = signal('');
  alertTitle = signal('');
  showModal = signal(false);
  alertType = signal<'info' | 'warning' | 'error' | 'success'>('success');
  availableRoles = signal<RoleType[]>([]);

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
    selectedRoles: this.fb.control([], Validators.required),
    shopId: this.fb.control(null, Validators.required),
  });

  async ngOnInit() {
    this.loadShops();
    this.setTranslateRoles();
  }

  async loadShops() {
    this.isLoading.set(true);
    try {
      const result = await this.shopService.getShopDetails({ deletedAt: null });
      this.availableShops.set(
        (result.data ?? []).map((shop) => ({
          id: shop.id,
          name: shop.name,
        })),
      );
    } catch (error) {
      // Puedes mostrar un error si lo deseas
      this.availableShops.set([]);
    } finally {
      this.isLoading.set(false);
    }
  }

  // 2. Gestionar el cambio en los Checkboxes
  onRoleChange(roleName: string, event: Event) {
    const isChecked = (event.target as HTMLInputElement).checked;
    const selectedRolesControl = this.signUpForm.controls.selectedRoles;
    let currentRoles = selectedRolesControl?.value || [];

    if (isChecked) {
      currentRoles = [...currentRoles, roleName];
    } else {
      currentRoles = currentRoles.filter((r) => r !== roleName);
    }

    if (selectedRolesControl) selectedRolesControl.setValue(currentRoles);

    if (selectedRolesControl) selectedRolesControl.markAsTouched();
  }

  // 3. Envío Seguro del Formulario
  async onSubmit() {
    if (this.signUpForm.invalid) {
      this.signUpForm.markAllAsTouched();
      this.showAlert(
        'Datos incompletos',
        'Complete campos y seleccione al menos un rol.',
        'warning',
      );
      return;
    }

    this.isLoading.set(true);
    const formValue = this.signUpForm.value;

    const payload = {
      email: formValue.email ?? '',
      password: formValue.password ?? '',
      firstName: formValue.firstName ?? '',
      lastName: formValue.lastName ?? '',
      authEmail: formValue.email ?? '',
      shopId: formValue.shopId ?? '',
      initialRoleNames: formValue.selectedRoles ?? [], // Array de roles
    };

    try {
      // Edge Function para registro seguro
      const result = await this.authService.registerEmployeeSecurely(payload);
      this.showAlert(
        '¡Registro exitoso!',
        `La cuenta del empleado ha sido creada con éxito. ID: ${result.user_id}.`,
        'success',
      );
      this.signUpForm.reset();
      this.signUpForm.controls.selectedRoles?.setValue([]);
      this.signUpForm.controls.shopId?.setValue('');
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'GENERIC_SERVER_ERROR';

      this.showAlert('¡Error al registrar!', this.getErrorTranslation(errorMessage), 'error');
    } finally {
      this.isLoading.set(false);
    }
  }

  private showAlert(
    title: string,
    message: string,
    type: 'info' | 'warning' | 'error' | 'success',
  ) {
    this.showModal.set(true);
    this.alertTitle.set(title);
    this.alertMessage.set(message);
    this.alertType.set(type);
  }

  private getErrorTranslation(message: string): string {
    // Busca la traducción exacta, si no existe usa el genérico
    return (
      this.translate.instant(`auth.errors.${message}`) ||
      this.translate.instant('auth.errors.generic')
    );
  }

  async setTranslateRoles() {
    const translate = await Promise.all(
      rolesUser.map(async (role) => {
        const label = await this.translate.get(`auth.roles.${role.name}`).toPromise();
        return { name: role.name, label }; // name: inglés, label: traducido
      }),
    );
    this.availableRoles.set(translate);
  }
}
