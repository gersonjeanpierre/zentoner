-- ######################################################################
-- # 1. BORRADO CONDICIONAL DE OBJETOS EXISTENTES
-- ######################################################################
DROP VIEW IF EXISTS public.employees_active CASCADE;
DROP VIEW IF EXISTS public.customers_active CASCADE;
DROP VIEW IF EXISTS public.people_active CASCADE;

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