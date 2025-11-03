-- DROP de funciones previas para evitar conflictos
DROP FUNCTION IF EXISTS public.rpc_create_employee(text, text, text, text, text, uuid, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_update_employee(uuid, text, text, text, text, text, uuid, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_delete_employee(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_get_employee_by_id(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_list_employees() CASCADE;

-- =========================
-- RPC: Crear empleado
-- =========================
CREATE OR REPLACE FUNCTION public.rpc_create_employee(
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_employee_code TEXT,
  p_auth_email TEXT,
  p_shop_id UUID,
  p_work_notes JSONB DEFAULT '{}'::jsonb,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller UUID := auth.uid();
  new_person_id UUID := gen_random_uuid();
  new_employee_id UUID := new_person_id;
  active_status_id BIGINT;
BEGIN
  -- Verifica permisos
  IF NOT auth_management.is_creator(caller) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: User lacks creator role.';
  END IF;

  -- Busca el status activo
  SELECT id INTO active_status_id FROM hr.employee_statuses WHERE code = 'ACTIVE' LIMIT 1;

  -- Crea la persona
  INSERT INTO core.persons (
    id, first_name, last_name, email, person_type, metadata, created_by_id
  ) VALUES (
    new_person_id, p_first_name, p_last_name, p_email, 'NATURAL', p_metadata, caller
  );

  -- Crea el empleado
  INSERT INTO hr.employees (
    id, shop_id, employee_code, auth_email, status_id, work_notes, created_by_id
  ) VALUES (
    new_employee_id, p_shop_id, p_employee_code, p_auth_email, active_status_id, p_work_notes, caller
  );

  RETURN new_employee_id;
END;
$$;

-- =========================
-- RPC: Actualizar empleado
-- =========================
CREATE OR REPLACE FUNCTION public.rpc_update_employee(
  p_id UUID,
  p_first_name TEXT,
  p_last_name TEXT,
  p_email TEXT,
  p_employee_code TEXT,
  p_auth_email TEXT,
  p_shop_id UUID,
  p_work_notes JSONB DEFAULT '{}'::jsonb,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF NOT auth_management.is_creator(caller) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: User lacks creator role.';
  END IF;

  -- Actualiza persona
  UPDATE core.persons
  SET first_name = p_first_name,
      last_name = p_last_name,
      email = p_email,
      metadata = p_metadata,
      updated_at = NOW(),
      updated_by_id = caller
  WHERE id = p_id;

  -- Actualiza empleado
  UPDATE hr.employees
  SET shop_id = p_shop_id,
      employee_code = p_employee_code,
      auth_email = p_auth_email,
      work_notes = p_work_notes,
      updated_at = NOW(),
      updated_by_id = caller
  WHERE id = p_id;
END;
$$;

-- =========================
-- RPC: Eliminar empleado (borrado lógico)
-- =========================
CREATE OR REPLACE FUNCTION public.rpc_delete_employee(
  p_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF NOT auth_management.is_creator(caller) THEN
    RAISE EXCEPTION 'PERMISSION_DENIED: User lacks creator role.';
  END IF;

  -- Borrado lógico en core.persons
  UPDATE core.persons
  SET deleted_at = NOW(),
      deleted_by_id = caller,
      updated_by_id = caller
  WHERE id = p_id;

  -- Borrado lógico en hr.employees
  UPDATE hr.employees
  SET deleted_by_id = caller,
      updated_by_id = caller,
      updated_at = NOW()
  WHERE id = p_id;
END;
$$;

-- =========================
-- RPC: Obtener empleado por ID
-- =========================
CREATE OR REPLACE FUNCTION public.rpc_get_employee_by_id(
  p_id UUID
)
RETURNS TABLE (
  id UUID,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  employee_code TEXT,
  auth_email TEXT,
  shop_id UUID,
  work_notes JSONB,
  metadata JSONB,
  status_id BIGINT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    e.id,
    p.first_name,
    p.last_name,
    p.email,
    e.employee_code,
    e.auth_email,
    e.shop_id,
    e.work_notes,
    p.metadata,
    e.status_id
  FROM hr.employees e
  JOIN core.persons p ON e.id = p.id
  WHERE e.id = p_id AND p.deleted_at IS NULL AND e.deleted_by_id IS NULL;
$$;

-- =========================
-- RPC: Listar empleados
-- =========================
CREATE OR REPLACE FUNCTION public.rpc_list_employees()
RETURNS TABLE (
  id UUID,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  employee_code TEXT,
  auth_email TEXT,
  shop_id UUID,
  work_notes JSONB,
  metadata JSONB,
  status_id BIGINT
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    e.id,
    p.first_name,
    p.last_name,
    p.email,
    e.employee_code,
    e.auth_email,
    e.shop_id,
    e.work_notes,
    p.metadata,
    e.status_id
  FROM hr.employees e
  JOIN core.persons p ON e.id = p.id
  WHERE p.deleted_at IS NULL AND e.deleted_by_id IS NULL;
$$;

-- =========================
-- GRANT para funciones
-- =========================
GRANT EXECUTE ON FUNCTION public.rpc_create_employee(text, text, text, text, text, uuid, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_update_employee(uuid, text, text, text, text, text, uuid, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_delete_employee(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_employee_by_id(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_list_employees() TO authenticated;

REVOKE EXECUTE ON FUNCTION public.rpc_create_employee(text, text, text, text, text, uuid, jsonb, jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_update_employee(uuid, text, text, text, text, text, uuid, jsonb, jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_delete_employee(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_get_employee_by_id(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_list_employees() FROM anon;