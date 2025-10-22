-- ----------------------------------------------------------------------
-- # 1. LIMPIEZA: BORRADO SEGURO Y ORDENADO DE OBJETOS EXISTENTES
-- ----------------------------------------------------------------------

-- 1.1. Vistas (Siempre primero)
DROP VIEW IF EXISTS public.customers_active CASCADE;

-- 1.2. Triggers (Antes de sus tablas asociadas)
DROP TRIGGER IF EXISTS trg_people_set_updated_at ON public.people;
DROP TRIGGER IF EXISTS trg_employees_set_updated_at ON public.employees;
DROP TRIGGER IF EXISTS trg_customers_set_updated_at ON public.customers;
DROP TRIGGER IF EXISTS trg_employee_roles_set_updated_at ON public.employee_roles;
DROP TRIGGER IF EXISTS trg_roles_set_updated_at ON public.roles;

-- 1.3. Funciones (Antes de sus tablas o RPCs que las usen)
DROP FUNCTION IF EXISTS public.set_updated_at;
DROP FUNCTION IF EXISTS public.is_super_admin_check(uuid); 
DROP FUNCTION IF EXISTS public.is_creator_check(uuid);
DROP FUNCTION IF EXISTS public.can_manage_employees(uuid);
DROP FUNCTION IF EXISTS public.upsert_customer(uuid, text, text, text, text, text, text, text, text, text, text, text, jsonb);
DROP FUNCTION IF EXISTS public.soft_delete_customer(uuid);

-- 1.4. Tablas (El orden es importante para evitar errores si CASCADE falla o no se usa)
DROP TABLE IF EXISTS public.employee_roles CASCADE;
DROP TABLE IF EXISTS public.roles CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.people CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;

-- 1.5. Tipos (EN COMÚN: Limpiar tipos ENUM propuestos)
DROP TYPE IF EXISTS public.person_type_enum;
DROP TYPE IF EXISTS public.customer_type_enum;