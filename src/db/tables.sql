-- ######################################################################
-- # 1. BORRADO CONDICIONAL DE OBJETOS EXISTENTES
-- ######################################################################

DROP VIEW IF EXISTS public.customers_active CASCADE;

-- Limpieza de tablas previas
DROP TABLE IF EXISTS public.employee_roles CASCADE;
DROP TABLE IF EXISTS public.roles CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.people CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;

-- ######################################################################
-- # 2. CREACIÓN DE TABLAS BASE Y ROLES
-- ######################################################################

-- === People table ===
-- Almacena el email personal/público.
CREATE TABLE public.people (
  id uuid PRIMARY KEY,
  first_name TEXT CHECK (char_length(first_name) <= 35),
  last_name TEXT CHECK (char_length(last_name) <= 80),
  legal_name TEXT CHECK (char_length(legal_name) <= 200),
  email TEXT UNIQUE CHECK (
    email IS NULL
    OR char_length(email) <= 150
    AND email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  ), -- Email personal/contacto
  phone TEXT CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{1,14}$'),
  dni TEXT CHECK (dni IS NULL OR dni ~ '^\d{8}$'),
  ruc TEXT CHECK (ruc IS NULL OR ruc ~ '^\d{11}$'),
  ce TEXT CHECK (ce IS NULL OR ce ~ '^[A-Za-z0-9]{6,20}$'),
  person_type TEXT CHECK (person_type IN ('PERSONA_JURIDICA', 'PERSONA_NATURAL')),
  metadata jsonb DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT TRUE,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Employees table ===
CREATE TABLE public.employees (
  id uuid PRIMARY KEY REFERENCES public.people (id),
  employee_code TEXT CHECK (
    employee_code IS NULL
    OR employee_code ~ '^[A-Za-z0-9]{1,14}$'
  ),
  auth_email TEXT UNIQUE CHECK (
    auth_email IS NULL
    OR char_length(auth_email) <= 150
    AND auth_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
  ), 
  hire_date date,
  salary numeric(12, 2),
  status TEXT DEFAULT 'active',
  work_notes jsonb DEFAULT '[]'::jsonb, --  Notas laborales en formato JSONB
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.customers (
  id uuid PRIMARY KEY REFERENCES public.people (id),
  customer_code TEXT CHECK (
    customer_code IS NULL
    OR customer_code ~ '^[A-Za-z0-9]{1,14}$'
  ),
  customer_type TEXT CHECK (
    customer_type IN (
      'nuevo',
      'frecuente',
      'imprentero_nuevo',
      'imprentero_frecuente'
    )
  ),
  notes jsonb DEFAULT '[]'::jsonb, -- Notas en formato JSONB para mayor flexibilidad
  created_by uuid REFERENCES auth.users (id) NOT NULL, -- El usuario de auth que creó este customer
  is_active BOOLEAN DEFAULT TRUE, -- Borrado lógico específico de la relación customer
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Roles y Employee_Roles === (Se mantienen sin cambios)
CREATE TABLE public.roles (
  id bigserial PRIMARY KEY,
  name TEXT unique not null CHECK (char_length(name) <= 50),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.employee_roles (
  employee_id uuid REFERENCES public.employees (id) on delete CASCADE,
  role_id bigint REFERENCES public.roles (id) on delete CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (employee_id, role_id)
);

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

-- ######################################################################
-- # 3. FUNCIONES Y TRIGGERS (ADICIONES Y AJUSTES)
-- ######################################################################

-- Limpieza de triggers previas
DROP TRIGGER IF EXISTS trg_people_set_updated_at ON public.people;
DROP TRIGGER IF EXISTS trg_employees_set_updated_at ON public.employees;
DROP TRIGGER IF EXISTS trg_customers_set_updated_at ON public.customers;
DROP TRIGGER IF EXISTS trg_employee_roles_set_updated_at ON public.employee_roles;
DROP TRIGGER IF EXISTS trg_roles_set_updated_at ON public.roles;

-- Limpieza de funciones previas
DROP FUNCTION IF EXISTS public.set_updated_at();
DROP FUNCTION IF EXISTS public.is_super_admin_check(uuid); 
DROP FUNCTION IF EXISTS public.is_creator_check(uuid);
DROP FUNCTION IF EXISTS public.can_manage_employees(uuid);


-- Función set_updated_at (se mantiene)
CREATE OR REPLACE FUNCTION public.set_updated_at() 
RETURNS 
  TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- TRIGGERS FALTANTES AÑADIDOS
CREATE TRIGGER trg_people_set_updated_at BEFORE UPDATE ON public.people FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_employees_set_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_customers_set_updated_at BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_employee_roles_set_updated_at BEFORE UPDATE ON public.employee_roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER trg_roles_set_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- FUNCIÓN DE CHECKEO DE ROL SUPER ADMIN
-- Mantener una función separada para la verificación del rol más alto.
CREATE OR REPLACE FUNCTION public.is_super_admin_check(user_id uuid)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.employee_roles er
    JOIN public.roles r ON er.role_id = r.id
    WHERE er.employee_id = user_id
      AND r.name = 'SuperAdmin'
  );
$$;

-- FUNCIÓN DE CHECKEO DE ROLES CREADORES (CLAVE para la Edge Function)
-- Verifica si el usuario logueado tiene el rol 'SuperAdmin' O 'Administrador'.
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
      AND r.name IN ('SuperAdmin', 'Administrador') -- Se verifica si tiene cualquiera de los roles
  );
$$;

-- FUNCIÓN DE CHECKEO DE ROLES MODIFICADORES DE EMPLEADOS
-- Verifica si el usuario logueado tiene el rol 'SuperAdmin', 'RRHH' O 'Contador'.
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

-- ----------------------------------------------------------------------
-- RPC: Función de Creación/Actualización (UPSERT) de Customer
-- ----------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.upsert_customer(
  p_id uuid, -- UUIDv7 para nuevo o ID existente
  p_first_name text,
  p_last_name text,
  p_legal_name text,
  p_email text,
  p_phone text,
  p_dni text,
  p_ruc text,
  p_ce text,
  p_person_type text,
  p_customer_code text,
  p_customer_type text,
  p_notes jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER -- Ejecutar como el dueño de la función (saltando RLS)
AS $$
DECLARE
  v_user_id uuid := auth.uid();
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
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    legal_name = EXCLUDED.legal_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    dni = EXCLUDED.dni,
    ruc = EXCLUDED.ruc,
    ce = EXCLUDED.ce,
    person_type = EXCLUDED.person_type,
    updated_at = NOW(),
    -- Importante: Restaurar el borrado lógico si se actualiza un cliente "borrado"
    deleted_at = NULL 
  WHERE public.people.id = p_id 
  -- Restricción de seguridad: Solo permitir UPDATE si el usuario logueado creó el customer
  AND EXISTS (SELECT 1 FROM public.customers c WHERE c.id = p_id AND c.created_by = v_user_id)
  RETURNING id INTO p_id; -- Aseguramos que la ID de retorno sea la ID de People

  -- 2. UPSERT en la tabla 'customers'
  INSERT INTO public.customers (
    id, customer_code, customer_type, notes, created_by
  )
  VALUES (
    p_id, p_customer_code, p_customer_type, p_notes, v_user_id
  )
  ON CONFLICT (id) DO UPDATE
  SET
    customer_code = EXCLUDED.customer_code,
    customer_type = EXCLUDED.customer_type,
    notes = EXCLUDED.notes,
    is_active = TRUE, -- Restaurar la actividad si fue borrado lógicamente
    updated_at = NOW()
  WHERE public.customers.id = p_id
  -- Restricción de seguridad: Solo permitir UPDATE si el usuario logueado creó el customer
  AND public.customers.created_by = v_user_id;

  RETURN p_id;
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
  -- 1. Verificar si el usuario actual es el creador del cliente
  IF NOT EXISTS (SELECT 1 FROM public.customers WHERE id = p_customer_id AND created_by = v_user_id) THEN
    -- Opcional: Permitir borrado por Super Admin
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

  -- Opcional: Se podría añadir un log de auditoría aquí mismo
END;
$$;


-- Vista para seleccionar customers activos (Unión people y customers)
CREATE OR REPLACE VIEW public.customers_active AS
SELECT 
    c.id,
    p.first_name,
    p.last_name,
    p.legal_name,
    p.email,
    p.phone,
    p.dni,
    p.ruc,
    p.ce,
    p.person_type,
    c.customer_code,
    c.customer_type,
    c.notes,
    c.created_by,
    c.is_active
FROM public.customers c
JOIN public.people p ON c.id = p.id
-- El cliente debe estar marcado como activo en customers Y no tener borrado lógico en people
WHERE c.is_active = TRUE AND p.deleted_at IS NULL;

-- ######################################################################
-- # 4. SEGURIDAD: ROW LEVEL SECURITY (RLS) OPTIMIZADA
-- ######################################################################

-- RLS Habilitadas (se mantiene)
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- 4.1. Políticas de Gestión de Roles y Empleados (Mantenidas)

-- Gestión de ROLES (Creación/Modificación): Solo 'super_admin'
-- Necesario para manejar la tabla 'roles' sin RPC.
DROP POLICY IF EXISTS "Super Admins can manage roles" ON public.roles;
CREATE POLICY "Super Admins can manage roles"
  ON public.roles
  FOR ALL
  TO authenticated
  USING (public.is_super_admin_check(auth.uid()))
  WITH CHECK (public.is_super_admin_check(auth.uid()));

-- Gestión de ASIGNACIÓN de ROLES: Permite a los 'creadores' asignar y quitar roles
-- Necesario para manejar la tabla 'employee_roles' sin RPC.
DROP POLICY IF EXISTS "Creators can manage all employee roles" ON public.employee_roles;
CREATE POLICY "Creators can manage all employee roles"
  ON public.employee_roles
  FOR ALL
  TO authenticated
  USING (public.is_creator_check(auth.uid()))
  WITH CHECK (public.is_creator_check(auth.uid()));

-- Gestión de DETALLES de EMPLEADOS (Status, Salario, Code)
-- Necesario para la autogestión de empleados y gestión por gestores.
DROP POLICY IF EXISTS "Manage or Own employee details" ON public.employees;
CREATE POLICY "Manage or Own employee details"
  ON public.employees
  FOR UPDATE
  TO authenticated 
  USING (
    id = auth.uid() -- Es mi propia fila
    OR public.can_manage_employees(auth.uid()) -- Soy un gestor
  )
  WITH CHECK (
    id = auth.uid()
    OR public.can_manage_employees(auth.uid())
  );

-- 4.2. Políticas de Lectura y Autogestión de Datos Personales

-- Permite que un usuario vea y ACTUALICE sus propios datos en 'people'
-- Mantenemos el UPDATE para autogestión de datos no relacionados con el estado de customer/employee.
DROP POLICY IF EXISTS "Users can view and update their own people record" ON public.people;
CREATE POLICY "Users can view and update their own people record"
  ON public.people
  FOR ALL
  TO authenticated 
  USING (id = auth.uid()) 
  WITH CHECK (id = auth.uid());

-- Permite que un usuario vea sus propios datos de empleado
DROP POLICY IF EXISTS "Users can view their own employee record" ON public.employees;
CREATE POLICY "Users can view their own employee record"
  ON public.employees
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- RLS en public.people: Lectura de clientes (Combinada y Optimizada)
-- Permite la lectura del propio registro O si el registro es parte de un cliente.
DROP POLICY IF EXISTS "Authenticated users can read their own or customer people records" ON public.people;
CREATE POLICY "Authenticated users can read their own or customer people records"
  ON public.people
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() 
  );


-- 4.3. Políticas Específicas para CUSTOMERS (Solo Lectura)

-- RLS en public.customers (Solo LECTURA)
-- Se eliminan las políticas FOR INSERT/UPDATE ya que se usa RPC.
-- Se mantiene la política de SELECT para clientes activos.
DROP POLICY IF EXISTS "All authenticated users can select active customers" ON public.customers;
CREATE POLICY "All authenticated users can select active customers"
  ON public.customers
  FOR SELECT
  TO authenticated
  USING (
    -- Solo verán registros si el customer y la persona están activos
    is_active = TRUE 
    AND EXISTS (
        SELECT 1 
        FROM public.people p 
        WHERE p.id = customers.id AND p.deleted_at IS NULL
    )
  );
  
-- *** RLS ADICIONAL: customers_active VIEW ***
-- La vista ya filtra por activo/no borrado.
ALTER VIEW public.customers_active SET (security_barrier = true);

-- ######################################################################
-- # 5. INICIALIZACIÓN: CREACIÓN DE ROLES
-- ######################################################################

INSERT INTO
  public.roles (name)
VALUES
  ('SuperAdmin'),
  ('Gerente'),
  ('Empleado'),
  ('Diseñador'),
  ('Cajero'),
  ('RRHH'),
  ('Contador'),
  ('Administrador'),
  ('Programador')
ON CONFLICT (name) DO NOTHING;