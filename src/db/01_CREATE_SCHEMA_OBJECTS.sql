--
-- ######################################################################
-- # 1. BORRADO CONDICIONAL Y CREACIÓN DE SCHEMAS
-- ######################################################################

-- Borrado condicional de vistas, tablas y funciones antiguas
DROP VIEW IF EXISTS sales.active_customers CASCADE;

DROP TABLE IF EXISTS hr.employee_roles CASCADE;

DROP TABLE IF EXISTS hr.roles CASCADE;

DROP TABLE IF EXISTS hr.employee_statuses CASCADE;

DROP TABLE IF EXISTS sales.customers CASCADE;

DROP TABLE IF EXISTS hr.employees CASCADE;

DROP TABLE IF EXISTS core.persons CASCADE;

DROP TABLE IF EXISTS core.audit_logs CASCADE;

DROP TABLE IF EXISTS core.shops CASCADE;

DROP SCHEMA IF EXISTS app_private CASCADE;

DROP SCHEMA IF EXISTS core CASCADE;

DROP SCHEMA IF EXISTS hr CASCADE;

DROP SCHEMA IF EXISTS sales CASCADE;

DROP SCHEMA IF EXISTS auth_management CASCADE;

DROP FUNCTION IF EXISTS public.set_updated_at () CASCADE;

DROP FUNCTION IF EXISTS public.set_audit_updated_by () CASCADE;

DROP FUNCTION IF EXISTS auth_management.is_super_admin (uuid) CASCADE;

DROP FUNCTION IF EXISTS auth_management.is_creator (uuid) CASCADE;

DROP FUNCTION IF EXISTS auth_management.can_manage_hr (uuid) CASCADE;

DROP FUNCTION IF EXISTS auth_management.is_employee (uuid) CASCADE;

-- 🔥 AÑADIDO: Drop de la nueva función para evitar errores en recreación
DROP FUNCTION IF EXISTS auth_management.is_universal_manager (uuid) CASCADE;

DROP FUNCTION IF EXISTS sales.upsert_customer (
    uuid,
    text,
    text,
    text,
    text,
    text,
    text,
    text,
    text,
    public.person_type_enum,
    text,
    text,
    jsonb
) CASCADE;

DROP FUNCTION IF EXISTS sales.soft_delete_customer (uuid) CASCADE;

DROP TYPE IF EXISTS public.person_type_enum;

-- ######################################################################
-- # 2. CREACIÓN DE TABLAS BASE (CORE)
-- ######################################################################

-- Creación de Schemas
CREATE SCHEMA IF NOT EXISTS app_private;

CREATE SCHEMA IF NOT EXISTS core;

CREATE SCHEMA IF NOT EXISTS hr;

CREATE SCHEMA IF NOT EXISTS sales;

CREATE SCHEMA IF NOT EXISTS auth_management;

-- Tipo ENUM para reutilización
CREATE TYPE public.person_type_enum AS ENUM ('JURIDICA', 'NATURAL');

-- === CORE.SHOPS (Locales de Imprenta Láser) ===
CREATE TABLE core.shops (
    id uuid PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    address TEXT,
    email TEXT UNIQUE,
    main_phone TEXT,
    secondary_phone TEXT,
    company_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    basic_service_providers jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by_id uuid REFERENCES auth.users (id),
    updated_by_id uuid REFERENCES auth.users (id),
    deleted_by_id uuid REFERENCES auth.users (id)
);

-- Constraints para CORE.SHOPS
ALTER TABLE core.shops
ADD CONSTRAINT chk_shops_name_length CHECK (char_length(name) <= 150),
ADD CONSTRAINT chk_shops_address_length CHECK (
    address IS NULL
    OR char_length(address) <= 200
),
ADD CONSTRAINT chk_shops_email_format CHECK (
    email IS NULL
    OR (
        char_length(email) <= 150
        AND email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
),
ADD CONSTRAINT chk_shops_main_phone_format CHECK (
    main_phone IS NULL
    OR main_phone ~ '^\+[1-9]\d{1,14}$'
),
ADD CONSTRAINT chk_shops_secondary_phone_format CHECK (
    secondary_phone IS NULL
    OR secondary_phone ~ '^\+[1-9]\d{1,14}$'
);

-- === CORE.PERSONS table === (Base para Clientes/Empleados)
CREATE TABLE core.persons (
    id uuid PRIMARY KEY,
    first_name TEXT,
    last_name TEXT,
    legal_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    dni TEXT,
    ruc TEXT UNIQUE,
    ce TEXT,
    person_type public.person_type_enum NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by_id uuid REFERENCES auth.users (id),
    updated_by_id uuid REFERENCES auth.users (id),
    deleted_by_id uuid REFERENCES auth.users (id)
);

-- Constraints para CORE.PERSONS
ALTER TABLE core.persons
ADD CONSTRAINT chk_persons_first_name_length CHECK (
    first_name IS NULL
    OR char_length(first_name) <= 35
),
ADD CONSTRAINT chk_persons_last_name_length CHECK (
    last_name IS NULL
    OR char_length(last_name) <= 80
),
ADD CONSTRAINT chk_persons_legal_name_length CHECK (
    legal_name IS NULL
    OR char_length(legal_name) <= 200
),
ADD CONSTRAINT chk_persons_email_format CHECK (
    email IS NULL
    OR (
        char_length(email) <= 150
        AND email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
),
ADD CONSTRAINT chk_persons_phone_format CHECK (
    phone IS NULL
    OR phone ~ '^\+[1-9]\d{1,14}$'
),
ADD CONSTRAINT chk_persons_dni_format CHECK (
    dni IS NULL
    OR dni ~ '^\d{8}$'
),
ADD CONSTRAINT chk_persons_ruc_format CHECK (
    ruc IS NULL
    OR ruc ~ '^\d{11}$'
),
ADD CONSTRAINT chk_persons_ce_format CHECK (
    ce IS NULL
    OR ce ~ '^[A-Za-z0-9]{6,20}$'
),
ADD CONSTRAINT chk_persons_dni_or_ce CHECK (
    (
        dni IS NOT NULL
        AND ce IS NULL
    )
    OR (
        dni IS NULL
        AND ce IS NOT NULL
    )
    OR (
        dni IS NULL
        AND ce IS NULL
    )
);

-- === CORE.AUDIT_LOGS ===
CREATE TABLE core.audit_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
    action TEXT NOT NULL,
    actor_id uuid REFERENCES auth.users (id),
    target_table TEXT,
    target_id uuid,
    status TEXT NOT NULL,
    ip TEXT,
    user_agent TEXT,
    payload jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ######################################################################
-- # 3. CREACIÓN DE TABLAS HR (HUMAN RESOURCES)
-- ######################################################################

-- === HR.EMPLOYEE_STATUSES (Nueva tabla de apoyo) ===
CREATE TABLE hr.employee_statuses (
    id SMALLSERIAL PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    is_employment_active BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- Constraints para HR.EMPLOYEE_STATUSES
ALTER TABLE hr.employee_statuses
ADD CONSTRAINT chk_employee_statuses_code_length CHECK (char_length(code) <= 30),
ADD CONSTRAINT chk_employee_statuses_name_length CHECK (char_length(name) <= 50);

-- === HR.ROLES ===
CREATE TABLE hr.roles (
    id BIGSERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Constraints para HR.ROLES
ALTER TABLE hr.roles
ADD CONSTRAINT chk_roles_name_length CHECK (char_length(name) <= 50);

-- === HR.EMPLOYEES table ===
CREATE TABLE hr.employees (
    id uuid PRIMARY KEY REFERENCES core.persons (id),
    shop_id uuid REFERENCES core.shops (id) NOT NULL,
    employee_code TEXT UNIQUE,
    auth_user_id uuid UNIQUE REFERENCES auth.users (id),
    auth_email TEXT UNIQUE,
    hire_date DATE,
    salary NUMERIC(12, 2),
    status_id BIGINT REFERENCES hr.employee_statuses (id) NOT NULL,
    work_notes jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by_id uuid REFERENCES auth.users (id) NOT NULL,
    updated_by_id uuid REFERENCES auth.users (id),
    deleted_by_id uuid REFERENCES auth.users (id)
);

-- Constraints para HR.EMPLOYEES
ALTER TABLE hr.employees
ADD CONSTRAINT chk_employees_code_format CHECK (
    employee_code IS NULL
    OR employee_code ~ '^[A-Za-z0-9]{1,14}$'
),
ADD CONSTRAINT chk_employees_email_format CHECK (
    auth_email IS NULL
    OR (
        char_length(auth_email) <= 150
        AND auth_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

-- === HR.EMPLOYEE_ROLES (Junction table) ===
CREATE TABLE hr.employee_roles (
    employee_id uuid REFERENCES hr.employees (id) ON DELETE CASCADE,
    role_id BIGINT REFERENCES hr.roles (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (employee_id, role_id)
);

-- ######################################################################
-- # 4. CREACIÓN DE TABLAS SALES (VENTAS/CLIENTES)
-- ######################################################################

CREATE TABLE sales.customers (
    id uuid PRIMARY KEY REFERENCES core.persons (id),
    customer_code TEXT UNIQUE,
    customer_type_code TEXT,
    notes jsonb DEFAULT '{}'::jsonb NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by_id uuid REFERENCES auth.users (id) NOT NULL,
    updated_by_id uuid REFERENCES auth.users (id),
    deleted_by_id uuid REFERENCES auth.users (id)
);

-- Constraints para SALES.CUSTOMERS
ALTER TABLE sales.customers
ADD CONSTRAINT chk_customers_code_format CHECK (
    customer_code IS NULL
    OR customer_code ~ '^[A-Za-z0-9]{1,14}$'
),
ADD CONSTRAINT chk_customers_type_code CHECK (
    customer_type_code IN (
        'new',
        'frequent',
        'printer_new',
        'printer_frequent'
    )
);

-- Vista para seleccionar customers activos (Unión persons y customers)
CREATE OR REPLACE VIEW sales.active_customers AS
SELECT c.id, p.first_name, p.last_name, p.legal_name, p.email, p.phone, p.dni, p.ruc, p.ce, p.person_type, c.customer_code, c.customer_type_code, c.notes, c.created_by_id
FROM sales.customers c
    JOIN core.persons p ON c.id = p.id
WHERE
    c.deleted_at IS NULL
    AND p.deleted_at IS NULL;

-- ######################################################################
-- # 5. FUNCIONES DE UTILIDAD Y AUTENTICACIÓN (INCLUYENDO AUDITORÍA)
-- ######################################################################

-- Función set_updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at() 
RETURNS 
  TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;

-- Función de Auditoría: Establece el usuario que actualiza
CREATE OR REPLACE FUNCTION public.set_audit_updated_by() 
RETURNS 
  TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_by_id = auth.uid(); RETURN NEW; END; $$;

-- TRIGGERS PARA UPDATED_AT
CREATE TRIGGER trg_shops_set_updated_at BEFORE UPDATE ON core.shops FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_persons_set_updated_at BEFORE UPDATE ON core.persons FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_employees_set_updated_at BEFORE UPDATE ON hr.employees FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_customers_set_updated_at BEFORE UPDATE ON sales.customers FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_roles_set_updated_at BEFORE UPDATE ON hr.roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_employee_roles_set_updated_at BEFORE UPDATE ON hr.employee_roles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_employee_statuses_set_updated_at BEFORE UPDATE ON hr.employee_statuses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- TRIGGERS PARA UPDATED_BY_ID
CREATE TRIGGER trg_shops_set_updated_by BEFORE UPDATE ON core.shops FOR EACH ROW EXECUTE FUNCTION public.set_audit_updated_by();

CREATE TRIGGER trg_persons_set_updated_by BEFORE UPDATE ON core.persons FOR EACH ROW EXECUTE FUNCTION public.set_audit_updated_by();
-- <--- Trigger para core.persons

CREATE TRIGGER trg_employees_set_updated_by BEFORE UPDATE ON hr.employees FOR EACH ROW EXECUTE FUNCTION public.set_audit_updated_by();

CREATE TRIGGER trg_customers_set_updated_by BEFORE UPDATE ON sales.customers FOR EACH ROW EXECUTE FUNCTION public.set_audit_updated_by();

-- FUNCIONES DE CHECKEO DE ROLES (auth_management)

-- 🔥 AÑADIDO: Función para verificar roles que tienen acceso universal a gestión (Gestores)
CREATE OR REPLACE FUNCTION auth_management.is_universal_manager(user_id uuid)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  -- Incluye todos los roles que no deben ser afectados por el shop_id
  SELECT EXISTS (
      SELECT 1 
      FROM hr.employee_roles er 
      JOIN hr.roles r ON er.role_id = r.id 
      WHERE er.employee_id = user_id 
      AND r.name IN ('SuperAdmin', 'Manager', 'HRManager', 'Accountant', 'Administrator', 'Developer')
  );
$$;

CREATE OR REPLACE FUNCTION auth_management.is_employee(user_id uuid)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM hr.employees WHERE id = user_id);
$$;

CREATE OR REPLACE FUNCTION auth_management.is_super_admin(user_id uuid)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  SELECT EXISTS (SELECT 1 FROM hr.employee_roles er JOIN hr.roles r ON er.role_id = r.id WHERE er.employee_id = user_id AND r.name = 'SuperAdmin');
$$;

CREATE OR REPLACE FUNCTION auth_management.is_creator(user_id uuid)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  -- Roles que pueden crear/gestionar usuarios y entidades principales
  SELECT EXISTS (SELECT 1 FROM hr.employee_roles er JOIN hr.roles r ON er.role_id = r.id WHERE er.employee_id = user_id AND r.name IN ('SuperAdmin', 'Administrator', 'HRManager'));
$$;

CREATE OR REPLACE FUNCTION auth_management.can_manage_hr(user_id uuid)
RETURNS BOOLEAN LANGUAGE sql STABLE AS $$
  -- Roles que pueden gestionar RR.HH. (empleados, salarios, estados, etc.)
  SELECT EXISTS (SELECT 1 FROM hr.employee_roles er JOIN hr.roles r ON er.role_id = r.id WHERE er.employee_id = user_id AND r.name IN ('SuperAdmin', 'HRManager', 'Accountant', 'Manager'));
$$;

-- ######################################################################
-- # 6. RPC: FUNCIONES DE MANIPULACIÓN DE DATOS (AJUSTADAS A AUDITORÍA Y RLS)
-- ######################################################################

-- RPC: Función de Creación/Actualización (UPSERT) de Customer (Sin cambios)
CREATE OR REPLACE FUNCTION sales.upsert_customer(
  p_id uuid, p_first_name text, p_last_name text, p_legal_name text, p_email text, p_phone text, p_dni text, p_ruc text, p_ce text,
  p_person_type_code public.person_type_enum, p_customer_code text, p_customer_type_code text, p_notes jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_user_id uuid := auth.uid(); v_person_id uuid := p_id;
BEGIN
  -- 1. UPSERT en la tabla 'core.persons'
  INSERT INTO core.persons (id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id)
  VALUES (v_person_id, p_first_name, p_last_name, p_legal_name, p_email, p_phone, p_dni, p_ruc, p_ce, p_person_type_code, v_user_id)
  ON CONFLICT (id) DO UPDATE
  SET first_name = EXCLUDED.first_name, last_name = EXCLUDED.last_name, legal_name = EXCLUDED.legal_name, email = EXCLUDED.email, 
      phone = EXCLUDED.phone, dni = EXCLUDED.dni, ruc = EXCLUDED.ruc, ce = EXCLUDED.ce, person_type = EXCLUDED.person_type,
      updated_at = NOW(), updated_by_id = v_user_id, deleted_at = NULL, deleted_by_id = NULL
  WHERE core.persons.id = v_person_id 
  RETURNING id INTO v_person_id;

  -- 2. UPSERT en la tabla 'sales.customers'
  INSERT INTO sales.customers (id, customer_code, customer_type_code, notes, created_by_id, updated_by_id)
  VALUES (v_person_id, p_customer_code, p_customer_type_code, p_notes, v_user_id, v_user_id) 
  ON CONFLICT (id) DO UPDATE
  SET customer_code = EXCLUDED.customer_code, customer_type_code = EXCLUDED.customer_type_code, notes = EXCLUDED.notes, 
      deleted_at = NULL, deleted_by_id = NULL, 
      updated_by_id = v_user_id, updated_at = NOW()
  WHERE sales.customers.id = v_person_id;

  RETURN p_id;
END;
$$;

-- RPC: Función de Borrado Lógico de Customer (Sin cambios)
CREATE OR REPLACE FUNCTION sales.soft_delete_customer(p_customer_id uuid)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE v_user_id uuid := auth.uid();
BEGIN
  -- Verificar permisos 
  IF NOT auth_management.is_employee(v_user_id) THEN
      RAISE EXCEPTION 'PERMISSION_DENIED: Only active employees can manage customer deletion.';
  END IF;

  -- 1. Borrado Lógico en 'core.persons'
  UPDATE core.persons SET deleted_at = NOW(), deleted_by_id = v_user_id, updated_by_id = v_user_id WHERE id = p_customer_id;

  -- 2. Borrado Lógico en 'sales.customers' (para la relación)
  UPDATE sales.customers SET deleted_at = NOW(), deleted_by_id = v_user_id WHERE id = p_customer_id;

  -- 3. Log de auditoría
  INSERT INTO core.audit_logs (action, actor_id, target_table, target_id, status, payload)
  VALUES ('soft_delete', v_user_id, 'sales.customers', p_customer_id, 'SUCCESS', jsonb_build_object('reason', 'soft deleted by employee'));
END;
$$;

-- ######################################################################
-- # 7. SEGURIDAD: ROW LEVEL SECURITY (RLS) - REFINADO POR ROLES GESTORES
-- ######################################################################

-- RLS Habilitadas (Sin cambios)
ALTER TABLE core.persons ENABLE ROW LEVEL SECURITY;

ALTER TABLE core.shops ENABLE ROW LEVEL SECURITY;

ALTER TABLE hr.employees ENABLE ROW LEVEL SECURITY;

ALTER TABLE hr.roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE hr.employee_roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

ALTER VIEW sales.active_customers SET (security_barrier = true);

-- POLÍTICAS REFINADAS
-- CORE.SHOPS: Se permite a todos los empleados ver los locales (metadato).
DROP POLICY "Employees only can access app data" ON core.shops;
-- Eliminamos la anterior

CREATE POLICY "All active employees can read shops" ON core.shops FOR
SELECT TO authenticated USING (
        auth_management.is_employee (auth.uid ())
        AND deleted_at IS NULL
    );

-- CORE.PERSONS (Datos Personales)

-- 🔥 AÑADIDO: Managers tienen control total (Universal) sobre todos los registros 'persons'.
CREATE POLICY "Universal Managers full access to persons" ON core.persons FOR ALL TO authenticated USING (
    auth_management.is_universal_manager (auth.uid ())
)
WITH
    CHECK (
        auth_management.is_universal_manager (auth.uid ())
    );

-- Self-Update: Permite al empleado editar su propio registro (Mantenemos, no aplica el filtro Manager aquí)
CREATE POLICY "Employee can view and update their own person record" ON core.persons FOR ALL TO authenticated USING (
    auth.uid () = id
    AND deleted_at IS NULL
)
WITH
    CHECK (
        auth.uid () = id
        AND deleted_at IS NULL
    );

-- Lectura de Clientes: Permite leer registros si son clientes activos (SOLO para empleados NO-Managers)
DROP POLICY "Allow read if is an active customer" ON core.persons;

CREATE POLICY "Non-Managers can read active customer persons" ON core.persons FOR
SELECT TO authenticated USING (
        deleted_at IS NULL
        -- Solo aplica si NO es un Manager Universal, para no duplicar permisos
        AND NOT auth_management.is_universal_manager (auth.uid ())
        AND EXISTS (
            SELECT 1
            FROM sales.customers sc
            WHERE
                sc.id = core.persons.id
                AND sc.deleted_at IS NULL
        )
    );

-- HR.EMPLOYEES (Registros Laborales)
-- Las políticas de HR ya son universales si usas can_manage_hr. No necesitan shop_id.

-- ⚠️ RLS de Lectura: Empleado solo se ve a sí mismo (Sin cambios)
CREATE POLICY "Employee can view their own record only" ON hr.employees FOR
SELECT TO authenticated USING (id = auth.uid ());

-- ⚠️ RLS de Lectura: HR Managers pueden ver todos los registros (Sin cambios - acceso universal)
CREATE POLICY "HR Managers can view all employee records" ON hr.employees FOR
SELECT TO authenticated USING (
        auth_management.can_manage_hr (auth.uid ())
    );

-- ⚠️ RLS de Escritura: HR Managers tienen control total (Sin cambios - acceso universal)
CREATE POLICY "HR Managers have full write access" ON hr.employees FOR ALL TO authenticated USING (
    auth_management.can_manage_hr (auth.uid ())
)
WITH
    CHECK (
        auth_management.can_manage_hr (auth.uid ())
    );

-- SALES.CUSTOMERS (Gestión de Clientes)
-- 🔥 REFINADO: Solo roles de creación/administración pueden gestionar clientes, no todos los empleados.
DROP POLICY "All Employees can manage customers" ON sales.customers;
-- Eliminamos la anterior

CREATE POLICY "Creator/Managers can manage customers" ON sales.customers FOR ALL TO authenticated USING (
    auth_management.is_creator (auth.uid ())
)
WITH
    CHECK (
        auth_management.is_creator (auth.uid ())
    );

-- ######################################################################
-- # 8. INICIALIZACIÓN DE DATOS (ROLES, LOCALES Y STATUSES)
-- ######################################################################

-- Inicialización de Statuses de Empleado (Sin cambios)
INSERT INTO
    hr.employee_statuses (
        code,
        name,
        is_employment_active
    )
VALUES (
        'ACTIVE',
        'Activo - Trabajando',
        TRUE
    ),
    (
        'INACTIVE',
        'Inactivo - Sin labores',
        FALSE
    ),
    (
        'ON_LEAVE',
        'Permiso/Licencia',
        FALSE
    ),
    (
        'TERMINATED',
        'Relación Laboral Terminada',
        FALSE
    )
ON CONFLICT (code) DO NOTHING;

-- Inicialización de Roles (Sin cambios)
INSERT INTO
    hr.roles (name, description)
VALUES (
        'SuperAdmin',
        'Control total del sistema y base de datos.'
    ),
    (
        'Manager',
        'Gerente de Local o Área, con capacidad de gestión HR.'
    ),
    (
        'Employee',
        'Empleado de Imprenta (producción, diseño).'
    ),
    (
        'Designer',
        'Diseñador Gráfico.'
    ),
    (
        'Cashier',
        'Cajero de Local (manejo de transacciones).'
    ),
    (
        'HRManager',
        'Recursos Humanos.'
    ),
    (
        'Accountant',
        'Contabilidad y finanzas.'
    ),
    (
        'Administrator',
        'Administrador de Sucursal.'
    ),
    (
        'Developer',
        'Mantenimiento y desarrollo de la app.'
    )
ON CONFLICT (name) DO NOTHING;

-- Inicialización de Locales (Sin cambios)
INSERT INTO
    core.shops (id, name, address)
VALUES (
        '019a1367-5dd3-79a4-a6cb-a3aa7a88612c',
        'ORBEGOSO',
        'JR. ORBEGOSO 243 PISO 1 STAND 243'
    )
ON CONFLICT (name) DO NOTHING;