-- Permitir ejecución a authenticated (clientes autenticados)
GRANT EXECUTE ON FUNCTION public.rpc_get_shops_for_user() TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_get_shop_by_id(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_create_shop(text,text,text,text,text,jsonb,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_update_shop(uuid,text,text,text,text,text,jsonb,jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.rpc_delete_shop(uuid) TO authenticated;

-- Revocar ejecución a anon
REVOKE EXECUTE ON FUNCTION public.rpc_get_shops_for_user() FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_get_shop_by_id(uuid) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_create_shop(text,text,text,text,text,jsonb,jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_update_shop(uuid,text,text,text,text,text,jsonb,jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.rpc_delete_shop(uuid) FROM anon;

-- Eliminar funciones RPC de shops si existen
DROP FUNCTION IF EXISTS public.rpc_get_shops_for_user() CASCADE;
DROP FUNCTION IF EXISTS public.rpc_get_shop_by_id(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_create_shop(text, text, text, text, text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_update_shop(uuid, text, text, text, text, text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS public.rpc_delete_shop(uuid) CASCADE;


-- #############################
-- FUNCIONES RPC DE SHOPS
-- #############################
CREATE OR REPLACE FUNCTION public.rpc_get_shops_for_user()
RETURNS TABLE (
  id uuid,
  name text,
  address text,
  email text,
  main_phone text,
  secondary_phone text,
  company_data jsonb,
  basic_service_providers jsonb,
  deleted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  created_by_id uuid,
  updated_by_id uuid,
  deleted_by_id uuid
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT s.id,
         s.name,
         s.address,
         s.email,
         s.main_phone,
         s.secondary_phone,
         s.company_data,
         s.basic_service_providers,
         s.deleted_at,
         s.created_at,
         s.updated_at,
         s.created_by_id,
         s.updated_by_id,
         s.deleted_by_id
  FROM core.shops s
  WHERE s.deleted_at IS NULL
    AND (
      EXISTS (
        SELECT 1 FROM hr.employees e
        WHERE e.shop_id = s.id
          AND e.auth_user_id = auth.uid()
          AND e.deleted_by_id IS NULL
      )
      OR COALESCE((SELECT auth_management.is_universal_manager(auth.uid())), false)
    );
$$;


CREATE OR REPLACE FUNCTION public.rpc_get_shop_by_id(p_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  address text,
  email text,
  main_phone text,
  secondary_phone text,
  company_data jsonb,
  basic_service_providers jsonb,
  deleted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  created_by_id uuid,
  updated_by_id uuid,
  deleted_by_id uuid
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT s.id,
         s.name,
         s.address,
         s.email,
         s.main_phone,
         s.secondary_phone,
         s.company_data,
         s.basic_service_providers,
         s.deleted_at,
         s.created_at,
         s.updated_at,
         s.created_by_id,
         s.updated_by_id,
         s.deleted_by_id
  FROM core.shops s
  WHERE s.id = p_id
    AND s.deleted_at IS NULL
    AND (
      EXISTS (SELECT 1 FROM hr.employees e WHERE e.shop_id = s.id AND e.auth_user_id = auth.uid() AND e.deleted_by_id IS NULL)
      OR COALESCE((SELECT auth_management.is_universal_manager(auth.uid())), false)
    );
$$;


CREATE OR REPLACE FUNCTION public.rpc_create_shop(
  p_name text,
  p_address text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_main_phone text DEFAULT NULL,
  p_secondary_phone text DEFAULT NULL,
  p_company_data jsonb DEFAULT '{}'::jsonb,
  p_basic_service_providers jsonb DEFAULT '{}'::jsonb
)
RETURNS TABLE (
  id uuid,
  name text,
  address text,
  email text,
  main_phone text,
  secondary_phone text,
  company_data jsonb,
  basic_service_providers jsonb,
  deleted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  created_by_id uuid,
  updated_by_id uuid,
  deleted_by_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller uuid := auth.uid();
  new_id uuid;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- Permiso: ejemplo de manager global; adapta a tu lógica
  IF NOT COALESCE((SELECT auth_management.is_universal_manager(caller)), false) THEN
    RAISE EXCEPTION 'permission denied';
  END IF;

  -- Validaciones coherentes con constraints
  IF char_length(coalesce(p_name, '')) = 0 OR char_length(p_name) > 150 THEN
    RAISE EXCEPTION 'invalid name';
  END IF;

  INSERT INTO core.shops (
    id, name, address, email, main_phone, secondary_phone,
    company_data, basic_service_providers, deleted_at,
    created_at, updated_at, created_by_id, updated_by_id, deleted_by_id
  )
  VALUES (
    gen_random_uuid(), p_name, p_address, p_email, p_main_phone, p_secondary_phone,
    p_company_data, p_basic_service_providers, NULL,
    now(), now(), caller, NULL, NULL
  )
  RETURNING id INTO new_id;

  -- Auditoría
  INSERT INTO core.audit_logs (id, action, actor_id, target_table, target_id, status, payload, created_at)
  VALUES (gen_random_uuid(), 'create_shop', caller, 'core.shops', new_id, 'ok',
          jsonb_build_object('name', p_name, 'email', p_email), now());

  RETURN QUERY
    SELECT s.id, s.name, s.address, s.email, s.main_phone, s.secondary_phone,
           s.company_data, s.basic_service_providers, s.deleted_at,
           s.created_at, s.updated_at, s.created_by_id, s.updated_by_id, s.deleted_by_id
    FROM core.shops s WHERE s.id = new_id;
END;
$$;


CREATE OR REPLACE FUNCTION public.rpc_update_shop(
  p_id uuid,
  p_name text DEFAULT NULL,
  p_address text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_main_phone text DEFAULT NULL,
  p_secondary_phone text DEFAULT NULL,
  p_company_data jsonb DEFAULT NULL,
  p_basic_service_providers jsonb DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  name text,
  address text,
  email text,
  main_phone text,
  secondary_phone text,
  company_data jsonb,
  basic_service_providers jsonb,
  deleted_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  created_by_id uuid,
  updated_by_id uuid,
  deleted_by_id uuid
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller uuid := auth.uid();
  rows_updated int;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- permiso: empleado de la tienda o manager global
  IF NOT (
    EXISTS (SELECT 1 FROM hr.employees e WHERE e.shop_id = p_id AND e.auth_user_id = caller AND e.deleted_by_id IS NULL)
    OR COALESCE((SELECT auth_management.is_universal_manager(caller)), false)
  ) THEN
    RAISE EXCEPTION 'permission denied';
  END IF;

  UPDATE core.shops
  SET name = COALESCE(p_name, name),
      address = COALESCE(p_address, address),
      email = COALESCE(p_email, email),
      main_phone = COALESCE(p_main_phone, main_phone),
      secondary_phone = COALESCE(p_secondary_phone, secondary_phone),
      company_data = COALESCE(p_company_data, company_data),
      basic_service_providers = COALESCE(p_basic_service_providers, basic_service_providers),
      updated_at = now(),
      updated_by_id = caller
  WHERE id = p_id AND deleted_at IS NULL;

  GET DIAGNOSTICS rows_updated = ROW_COUNT;

  IF rows_updated = 0 THEN
    RAISE EXCEPTION 'not_found_or_no_permission';
  END IF;

  INSERT INTO core.audit_logs (id, action, actor_id, target_table, target_id, status, payload, created_at)
  VALUES (gen_random_uuid(), 'update_shop', caller, 'core.shops', p_id, 'ok',
          jsonb_build_object(
            'changed_fields',
            jsonb_build_object(
              'name', p_name IS NOT NULL,
              'address', p_address IS NOT NULL,
              'email', p_email IS NOT NULL,
              'main_phone', p_main_phone IS NOT NULL,
              'secondary_phone', p_secondary_phone IS NOT NULL
            )
          ), now());

  RETURN QUERY SELECT id, name, address, email, main_phone, secondary_phone, company_data, basic_service_providers, deleted_at, created_at, updated_at, created_by_id, updated_by_id, deleted_by_id
  FROM core.shops WHERE id = p_id;
END;
$$;


CREATE OR REPLACE FUNCTION public.rpc_delete_shop(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  caller uuid := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'unauthenticated';
  END IF;

  -- permiso: manager global
  IF NOT COALESCE((SELECT auth_management.is_universal_manager(caller)), false) THEN
    RAISE EXCEPTION 'permission denied';
  END IF;

  UPDATE core.shops
  SET deleted_at = now(), deleted_by_id = caller
  WHERE id = p_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'not_found_or_no_permission';
  END IF;

  INSERT INTO core.audit_logs (id, action, actor_id, target_table, target_id, status, payload, created_at)
  VALUES (gen_random_uuid(), 'delete_shop', caller, 'core.shops', p_id, 'ok', NULL, now());
END;
$$;

