export interface CustomerPayload {
  id: string; // UUIDv7

  // Datos de la tabla 'people' (Asegúrate de que todos los tipos de campo sean opcionales si lo son en la DB)
  firstName: string;
  lastName: string;
  legalName: string | null;
  email: string | null;
  phone: string | null;
  dni: string | null;
  ruc: string | null;
  ce: string | null;
  personType: 'juridico' | 'natural';

  // Datos de la tabla 'customers'
  customerCode: string | null;
  customerType: 'nuevo' | 'frecuente' | 'imprentero_nuevo' | 'imprentero_frecuente';
  notes: Record<string, string> | null;
}

export interface CustomerView {
  // --- Campos de People ---
  id: string; // UUID
  firstName: string | null;
  lastName: string | null;
  legalName: string | null;
  email: string | null; // Email personal/contacto
  phone: string | null;
  dni: string | null;
  ruc: string | null;
  ce: string | null;
  personType: 'juridico' | 'natural';

  // --- Campos de Customers ---
  customerCode: string | null;
  customerType: string; // 'nuevo', 'frecuente', etc.
  notes: string | null; // NOTA: Si lo recuperas como JSONB, usa 'any' o 'NoteEntry[]'.
  // Si la vista lo transforma a TEXT/STRING, usa 'string | null'.

  // --- Campos de Auditoría y Estado ---
  isActive: boolean; // El estado lógico del customer (aunque la vista ya filtra por TRUE)
  createdBy: string | null; // UUID del empleado que lo creó
}