import { FormControl } from "@angular/forms";

export interface SignUpForm {
  email: FormControl<string | null>;
  password: FormControl<string | null>;
}