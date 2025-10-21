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
  p_notes text
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