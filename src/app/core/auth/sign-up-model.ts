import { FormControl } from "@angular/forms";

export interface SignUpForm {
  email: FormControl<string | null>;
  password: FormControl<string | null>;
  firstName?: FormControl<string | null>;
  lastName?: FormControl<string | null>;
  selectedRoles?: FormControl<string[] | null>;
}