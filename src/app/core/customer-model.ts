export interface CustomerModel {
  id?: string;
  typePerson?: string | null;
  typeClient?: string | null;
  phone?: string | null;
  fullName?: string | null;
  socialReason?: string | null;
  dni?: string | null;
  ruc?: string | null;
  ce?: string | null;
  email?: string | null;
  isActive?: boolean;
}