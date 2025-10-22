-- ----------------------------------------------------------------------
-- # 2. CREACIÓN DE OBJETOS
-- ----------------------------------------------------------------------

-- 2.1. Tipos ENUM (Recomendado para tipos fijos)
CREATE TYPE public.person_type_enum AS ENUM ('PERSONA_JURIDICA', 'PERSONA_NATURAL');
CREATE TYPE public.customer_type_enum AS ENUM ('NUEVO', 'FRECUENTE', 'IMPRENTERO_NUEVO', 'IMPRENTERO_FRECUENTE', 'VIP');

-- 2.2. Creación de Tablas Base

-- === People table ===
CREATE TABLE public.people (
  id uuid PRIMARY KEY,
  first_name TEXT CHECK (char_length(first_name) <= 35),
  last_name TEXT CHECK (char_length(last_name) <= 80),
  legal_name TEXT CHECK (char_length(legal_name) <= 200),
  
  -- Validación de Email más robusta
  email TEXT UNIQUE CHECK (
    email IS NULL
    OR (char_length(email) <= 150 AND email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
  ), 
  
  -- Validación de Número de Teléfono E.164
  phone TEXT CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{6,14}$'), -- Ajuste a 6-14 dígitos
  
  -- Documentos de Identidad (Se mantiene por ahora, ver optimizaciones)
  dni TEXT CHECK (dni IS NULL OR dni ~ '^\d{8}$'),
  ruc TEXT CHECK (ruc IS NULL OR ruc ~ '^\d{11}$'),
  ce TEXT CHECK (ce IS NULL OR ce ~ '^[A-Za-z0-9]{6,20}$'),

  -- Uso del tipo ENUM recomendado
  person_type public.person_type_enum,
  
  metadata jsonb DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Employees table ===
CREATE TABLE public.employees (
  id uuid PRIMARY KEY REFERENCES public.people (id) ON DELETE CASCADE, -- Usar ON DELETE CASCADE para mantener la integridad en hard delete (aunque se use soft delete)
  employee_code TEXT UNIQUE CHECK (
    employee_code IS NULL
    OR employee_code ~ '^[A-Za-z0-9]{1,14}$'
  ), -- Añadir UNIQUE
  auth_email TEXT UNIQUE CHECK (
    auth_email IS NULL
    OR (char_length(auth_email) <= 150 AND auth_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
  ), 
  hire_date date,
  salary numeric(12, 2),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave', 'terminated')), -- Sugerencia: Añadir check
  work_notes jsonb DEFAULT '[]'::jsonb, 
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Customers table ===
CREATE TABLE public.customers (
  id uuid PRIMARY KEY REFERENCES public.people (id) ON DELETE CASCADE,
  customer_code TEXT UNIQUE CHECK (
    customer_code IS NULL
    OR customer_code ~ '^[A-Za-z0-9]{1,14}$'
  ), -- Añadir UNIQUE
  customer_type public.customer_type_enum NOT NULL, -- Uso de ENUM y NOT NULL
  notes jsonb DEFAULT '[]'::jsonb,
  created_by uuid REFERENCES auth.users (id) NOT NULL, 
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Roles y Employee_Roles ===
CREATE TABLE public.roles (
  id bigserial PRIMARY KEY,
  name TEXT unique NOT NULL CHECK (char_length(name) <= 50),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.employee_roles (
  employee_id uuid REFERENCES public.employees (id) ON DELETE CASCADE,
  role_id bigint REFERENCES public.roles (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (employee_id, role_id)
);

-- === Audit Logs ===
CREATE TABLE public.audit_logs (
   id uuid PRIMARY KEY DEFAULT gen_random_uuid(), 
   action text NOT NULL, 
   actor_id uuid NOT NULL, 
   target_id uuid, 
   status text NOT NULL, 
   ip text, 
   user_agent text, 
   payload jsonb, 
   created_at timestamptz NOT NULL DEFAULT now() 
);

-- 2.3. Funciones y Triggers (Logic)

-- Función set_updated_at 
CREATE OR REPLACE FUNCTION public.set_updated_at() 
RETURNS 
  TRIGGER 
  LANGUAGE plpgsql 
  AS $$
BEGIN 
  NEW.updated_at = NOW(); 
  RETURN NEW; 
END; 
$$;

-- Triggers de actualización (Mantenidos)
CREATE TRIGGER trg_people_set_updated_at BEFORE UPDATE ON public.people FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_employees_set_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_customers_set_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_employee_roles_set_updated_at BEFORE UPDATE ON public.employee_roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_roles_set_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Funciones de Chequeo de Roles (Optimizadas con STABLE)
CREATE OR REPLACE FUNCTION public.is_super_admin_check(user_id uuid)
RETURNS BOOLEAN
LANGUAGE sql
STABLE -- Mejor para consultas SELECT
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.employee_roles er
    JOIN public.roles r ON er.role_id = r.id
    WHERE er.employee_id = user_id
      AND r.name = 'SuperAdmin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_creator_check(user_id uuid)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.employee_roles er
    JOIN public.roles r ON er.role_id = r.id
    WHERE er.employee_id = user_id
      AND r.name IN ('SuperAdmin', 'Administrador')
  );
$$;

CREATE OR REPLACE FUNCTION public.can_manage_employees(user_id uuid)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.employee_roles er
    JOIN public.roles r ON er.role_id = r.id
    WHERE er.employee_id = user_id
      AND r.name IN ('SuperAdmin', 'RRHH', 'Contador')
  );
$$;

-- RPCs (Mantenidas, con validaciones internas de seguridad)
-- Nota: Estas funciones deben ser definidas en Supabase con SECURITY DEFINER
-- para poder saltar las RLS. La seguridad se gestiona internamente con auth.uid()
-- y los checks de rol/creador.

-- ----------------------------------------------------------------------
-- RPC: Función de Creación/Actualización (UPSERT) de Customer
-- ----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_customer(
  p_id uuid, p_first_name text, p_last_name text, p_legal_name text,
  p_email text, p_phone text, p_dni text, p_ruc text, p_ce text,
  p_person_type public.person_type_enum, -- Usar ENUM
  p_customer_code text,
  p_customer_type public.customer_type_enum, -- Usar ENUM
  p_notes jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER 
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_id_out uuid;
BEGIN
  -- 1. UPSERT en la tabla 'people'
  INSERT INTO public.people (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type
  )
  VALUES (
    p_id, p_first_name, p_last_name, p_legal_name, p_email, p_phone, p_dni, p_ruc, p_ce, p_person_type
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    first_name = EXCLUDED.first_name, last_name = EXCLUDED.last_name, legal_name = EXCLUDED.legal_name,
    email = EXCLUDED.email, phone = EXCLUDED.phone, dni = EXCLUDED.dni, ruc = EXCLUDED.ruc, ce = EXCLUDED.ce,
    person_type = EXCLUDED.person_type, updated_at = NOW(), deleted_at = NULL 
  WHERE public.people.id = p_id 
  -- Restricción de seguridad: Solo permitir UPDATE si el usuario logueado es creador O SuperAdmin
  AND (
    EXISTS (SELECT 1 FROM public.customers c WHERE c.id = p_id AND c.created_by = v_user_id)
    OR public.is_super_admin_check(v_user_id) -- Añadir chequeo de SuperAdmin para gestión
  )
  RETURNING id INTO v_id_out; 

  -- 2. UPSERT en la tabla 'customers'
  INSERT INTO public.customers (
    id, customer_code, customer_type, notes, created_by
  )
  VALUES (
    v_id_out, p_customer_code, p_customer_type, p_notes, v_user_id
  )
  ON CONFLICT (id) DO UPDATE
  SET
    customer_code = EXCLUDED.customer_code, customer_type = EXCLUDED.customer_type,
    notes = EXCLUDED.notes, is_active = TRUE, updated_at = NOW()
  WHERE public.customers.id = v_id_out
  -- Restricción de seguridad: Solo permitir UPDATE si el usuario logueado es creador O SuperAdmin
  AND (
    public.customers.created_by = v_user_id
    OR public.is_super_admin_check(v_user_id) -- Añadir chequeo de SuperAdmin para gestión
  );

  RETURN v_id_out;
END;
$$;


-- ----------------------------------------------------------------------
-- RPC: Función de Borrado Lógico de Customer
-- ----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.soft_delete_customer(
  p_customer_id uuid
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  -- 1. Verificar si el usuario actual es el creador del cliente O Super Admin
  IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = p_customer_id AND created_by = v_user_id) THEN
    IF NOT public.is_super_admin_check(v_user_id) THEN
        RAISE EXCEPTION 'PERMISSION_DENIED: User is not the creator or a Super Admin.';
    END IF;
  END IF;

  -- 2. Borrado Lógico en 'people'
  UPDATE public.people
  SET 
    deleted_at = NOW()
  WHERE id = p_customer_id;

  -- 3. Borrado Lógico en 'customers'
  UPDATE public.customers
  SET 
    is_active = FALSE
  WHERE id = p_customer_id;

END;
$$;

-- Vista para seleccionar customers activos (Unión people y customers)
CREATE OR REPLACE VIEW public.customers_active AS
SELECT 
    c.id, p.first_name, p.last_name, p.legal_name, p.email, p.phone, p.dni, p.ruc, p.ce, p.person_type,
    c.customer_code, c.customer_type, c.notes, c.created_by, c.is_active,
    p.created_at, p.updated_at -- Incluir timestamps de people para la vista
FROM public.customers c
JOIN public.people p ON c.id = p.id
WHERE c.is_active = TRUE AND p.deleted_at IS NULL;

-- 2.4. Seguridad: Row Level Security (RLS) Optimizada

ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- ... [Mantenimiento de Políticas RLS: roles, employee_roles, employees, people] ...

-- RLS en public.people (REVISADO Y CORREGIDO)
-- La política original para 'people' solo permitía ver el registro propio. 
-- Es necesario permitir ver los registros de personas que son clientes activos para el correcto funcionamiento de la vista RLS.
DROP POLICY IF EXISTS "Authenticated users can read their own or customer people records" ON public.people;
CREATE POLICY "Authenticated users can read their own or customer people records"
  ON public.people
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() -- Puedo ver mi propio registro
    OR EXISTS (
        -- Puedo ver el registro si es un cliente activo y no ha sido borrado lógicamente
        SELECT 1 
        FROM public.customers c 
        WHERE c.id = people.id AND c.is_active = TRUE
    )
  );

-- *** RLS ADICIONAL: customers_active VIEW ***
-- (Mantenido) La vista ya filtra por activo/no borrado.
ALTER VIEW public.customers_active SET (security_barrier = true);

-- 2.5. Inicialización
INSERT INTO
  public.roles (name)
VALUES
  ('SuperAdmin'), ('Gerente'), ('Empleado'), ('Diseñador'), ('Cajero'), ('RRHH'), ('Contador'), ('Administrador'), ('Programador')
ON CONFLICT (name) DO NOTHING;