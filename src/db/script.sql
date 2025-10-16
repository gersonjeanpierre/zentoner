-- DROP dependent objects then recreate schema for people/employees/customers with validations + partial indexes

-- 1) Drop views if exist
DROP VIEW IF EXISTS employees_active CASCADE;
DROP VIEW IF EXISTS customers_active CASCADE;
DROP VIEW IF EXISTS people_active CASCADE;

-- 2) Drop functions if exist (safe to drop even if tables absent)
DROP FUNCTION IF EXISTS propagate_soft_delete_people();
DROP FUNCTION IF EXISTS set_updated_at();

-- 3) Drop triggers if exist (safe: IF EXISTS avoids errors when tables missing)
DROP TRIGGER IF EXISTS trg_people_propagate_soft_delete ON people;
DROP TRIGGER IF EXISTS trg_people_set_updated_at ON people;
DROP TRIGGER IF EXISTS trg_employees_set_updated_at ON employees;
DROP TRIGGER IF EXISTS trg_customers_set_updated_at ON customers;

-- 4) Drop tables in dependency order (destructive)
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS people CASCADE;

-- 5) Recreate tables

-- Optional extension (uncomment if DB-side UUID generation is needed)
-- CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- === People table ===
CREATE TABLE IF NOT EXISTS people (
  id uuid PRIMARY KEY,
  first_name text CHECK (char_length(first_name) <= 35),
  last_name text CHECK (char_length(last_name) <= 80),
  legal_name text CHECK (char_length(legal_name) <= 200),
  email text CHECK (email IS NULL OR char_length(email) <= 150 AND email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
  phone text CHECK (phone IS NULL OR phone ~ '^\+[1-9]\d{1,14}$'), -- E.164
  dni text CHECK (dni IS NULL OR dni ~ '^\d{8}$'),
  ruc text CHECK (ruc IS NULL OR ruc ~ '^\d{11}$'),
  ce text CHECK (ce IS NULL OR ce ~ '^[A-Za-z0-9]{6,20}$'),
  person_type text CHECK (person_type IN ('juridico','natural')),
  metadata jsonb DEFAULT '{}'::jsonb,
  is_active boolean DEFAULT true,
  deleted_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Indexes for people (partial to avoid indexing NULLs)
CREATE INDEX IF NOT EXISTS idx_people_phone ON people (phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_people_dni ON people (dni) WHERE dni IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_people_ruc ON people (ruc) WHERE ruc IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_people_ce ON people (ce) WHERE ce IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_people_email_lower ON people ((lower(email))) WHERE email IS NOT NULL;

-- Partial indexes to support common queries (active / not deleted)
CREATE INDEX IF NOT EXISTS idx_people_active_name ON people (last_name, first_name) WHERE deleted_at IS NULL AND is_active = true;
CREATE INDEX IF NOT EXISTS idx_people_search_metadata ON people USING gin (metadata) WHERE deleted_at IS NULL;

-- === Employees table ===
CREATE TABLE IF NOT EXISTS employees (
  id uuid PRIMARY KEY REFERENCES people(id),
  employee_code text CHECK (employee_code IS NULL OR employee_code ~ '^[A-Za-z0-9]{1,14}$'),
  role text CHECK (role IS NULL OR char_length(role) <= 100),
  hire_date date,
  salary numeric(12,2),
  status text DEFAULT 'active',
  work_notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_employees_employee_code ON employees (employee_code) WHERE employee_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_employees_role ON employees (role) WHERE role IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_employees_status_hiredate ON employees (status, hire_date) WHERE status IS NOT NULL;

-- === Customers table ===
CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY REFERENCES people(id),
  customer_code text CHECK (customer_code IS NULL OR customer_code ~ '^[A-Za-z0-9]{1,14}$'),
  customer_type text CHECK (customer_type IN ('nuevo','frecuente','imprentero_nuevo','imprentero_frecuente')),
  notes text,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_customers_customer_code ON customers (customer_code) WHERE customer_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_customer_type ON customers (customer_type) WHERE customer_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_customers_active ON customers (customer_type) WHERE is_active = true;

-- 6) Trigger function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_people_set_updated_at
BEFORE UPDATE ON people
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_employees_set_updated_at
BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_customers_set_updated_at
BEFORE UPDATE ON customers
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 7) Soft-delete propagation trigger
CREATE OR REPLACE FUNCTION propagate_soft_delete_people()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  -- When a person is soft-deleted (deleted_at set), mark dependent records as inactive/terminated
  IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    UPDATE employees
      SET status = 'terminated', updated_at = now()
      WHERE id = NEW.id;

    UPDATE customers
      SET is_active = false, updated_at = now()
      WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_people_propagate_soft_delete
AFTER UPDATE ON people
FOR EACH ROW
WHEN (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL)
EXECUTE FUNCTION propagate_soft_delete_people();

-- 8) Optional: Views to simplify selecting active people
CREATE OR REPLACE VIEW people_active AS
SELECT * FROM people WHERE deleted_at IS NULL AND is_active = true;

CREATE OR REPLACE VIEW customers_active AS
SELECT * FROM customers WHERE is_active = true;

CREATE OR REPLACE VIEW employees_active AS
SELECT * FROM employees WHERE status = 'active';
