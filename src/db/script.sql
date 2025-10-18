-- ######################################################################
-- # 1. BORRADO CONDICIONAL DE OBJETOS EXISTENTES
-- ######################################################################

-- Limpieza de dependencias: se mantiene tu script original, es robusto.
DROP TRIGGER IF EXISTS trg_people_set_updated_at ON public.people;
DROP TRIGGER IF EXISTS trg_employees_set_updated_at ON public.employees;
DROP TRIGGER IF EXISTS trg_customers_set_updated_at ON public.customers;
DROP TRIGGER IF EXISTS trg_employee_roles_set_updated_at ON public.employee_roles;
DROP TRIGGER IF EXISTS trg_roles_set_updated_at ON public.roles;

DROP VIEW IF EXISTS public.employees_active CASCADE;
DROP VIEW IF EXISTS public.customers_active CASCADE;
DROP VIEW IF EXISTS public.people_active CASCADE;

DROP FUNCTION IF EXISTS public.set_updated_at();
DROP FUNCTION IF EXISTS public.is_super_admin_check(uuid); 
DROP FUNCTION IF EXISTS public.is_creator_check(uuid);

DROP TABLE IF EXISTS public.employee_roles CASCADE;
DROP TABLE IF EXISTS public.roles CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.people CASCADE;

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
  person_type TEXT CHECK (person_type IN ('juridico', 'natural')),
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
  work_notes jsonb DEFAULT '[]'::jsonb, -- Se mantiene tu mejora a JSONB
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- === Customers table ===
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
  notes TEXT,
  is_active BOOLEAN DEFAULT TRUE,
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

-- ######################################################################
-- # 3. FUNCIONES Y TRIGGERS (ADICIONES Y AJUSTES)
-- ######################################################################

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
      AND r.name = 'super_admin'
  );
$$;

-- FUNCIÓN DE CHECKEO DE ROLES CREADORES (CLAVE para la Edge Function)
-- Verifica si el usuario logueado tiene el rol 'super_admin' O 'administrador'.
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
      AND r.name IN ('super_admin', 'administrador') -- Se verifica si tiene cualquiera de los roles
  );
$$;

-- FUNCIÓN DE CHECKEO DE ROLES MODIFICADORES DE EMPLEADOS
-- Verifica si el usuario logueado tiene el rol 'super_admin', 'rrhh' O 'contador'.
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
      AND r.name IN ('super_admin', 'rrhh', 'contador')
  );
$$;

-- ######################################################################
-- # 4. SEGURIDAD: ROW LEVEL SECURITY (RLS)
-- ######################################################################

-- RLS Habilitadas (se mantiene)
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
-- 4.1. Políticas de Gestión de Roles y Empleados

-- Gestión de ROLES (Creación/Modificación): Solo 'super_admin'
DROP POLICY IF EXISTS "Super Admins can manage roles" ON public.roles;
CREATE POLICY "Super Admins can manage roles"
  ON public.roles
  FOR ALL
  TO authenticated
  USING (public.is_super_admin_check(auth.uid()))
  WITH CHECK (public.is_super_admin_check(auth.uid()));

-- Gestión de ASIGNACIÓN de ROLES: Permite a los 'creadores' asignar y quitar roles
DROP POLICY IF EXISTS "Creators can manage all employee roles" ON public.employee_roles;
CREATE POLICY "Creators can manage all employee roles"
  ON public.employee_roles
  FOR ALL
  TO authenticated
  USING (public.is_creator_check(auth.uid()))
  WITH CHECK (public.is_creator_check(auth.uid()));

-- Gestión de DETALLES de EMPLEADOS (Status, Salario, Code)
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

-- 4.2. Políticas de Lectura (Ajustadas para la gestión de datos personales)

-- Permite que un usuario vea y ACTUALICE sus propios datos en 'people'
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

-- ######################################################################
-- # 5. INICIALIZACIÓN: CREACIÓN DE ROLES
-- ######################################################################

INSERT INTO
  public.roles (name)
VALUES
  ('super_admin'),
  ('gerente'),
  ('empleado'),
  ('diseñador'),
  ('cajero'),
  ('rrhh'),
  ('contador'),
  ('administrador')
ON CONFLICT (name) DO NOTHING;