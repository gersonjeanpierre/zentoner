-- Ejecutar en la Consola SQL de Supabase
DO $$
DECLARE
    admin_auth_email text := 'admin@lasercolorveloz.com'; -- ! DEBE COINCIDIR con el email del Paso 6.1
    admin_uuid uuid;
    super_admin_role_id bigint;
BEGIN
    -- 1. Obtener el ID del usuario registrado en Auth
    SELECT id INTO admin_uuid FROM auth.users WHERE email = admin_auth_email;
    
    IF admin_uuid IS NULL THEN
        RAISE EXCEPTION 'El usuario % no existe en auth.users.', admin_auth_email;
    END IF;

    -- 2. Obtener IDs de roles necesarios
    SELECT id INTO super_admin_role_id FROM public.roles WHERE name = 'super_admin';

    -- 3. Crear el Perfil en PEOPLE
    -- Asumimos el Auth Email como Email personal/público por simplicidad inicial
    INSERT INTO public.people (id, email, first_name, last_name, person_type)
    VALUES (admin_uuid, admin_auth_email, 'Super', 'Admin', 'natural')
    ON CONFLICT (id) DO NOTHING;

    -- 4. Crear el registro de EMPLOYEES
    INSERT INTO public.employees (id, auth_email, status, hire_date)
    VALUES (admin_uuid, admin_auth_email, 'active', CURRENT_DATE)
    ON CONFLICT (id) DO NOTHING;
    
    -- 5. Asignar el rol SUPER_ADMIN
    INSERT INTO public.employee_roles (employee_id, role_id)
    VALUES (admin_uuid, super_admin_role_id)
    ON CONFLICT (employee_id, role_id) DO NOTHING;
    
    RAISE NOTICE '¡Super Administrador % creado y listo para usar la Edge Function!', admin_auth_email;
END $$;