SELECT * FROM hr.employees WHERE id = 'f147d494-06f9-4e3f-af5f-01d39b37de9a';

SELECT * FROM hr.employee_roles;
SELECT * FROM hr.roles;

SELECT
    t1.employee_id,
    t2.name AS role_name
FROM hr.employee_roles t1
JOIN hr.roles t2 ON t1.role_id = t2.id
WHERE t1.employee_id = 'f147d494-06f9-4e3f-af5f-01d39b37de9a'
  AND t2.name IN ('SuperAdmin', 'Administrator', 'HRManager');

SELECT auth_management.is_creator('f147d494-06f9-4e3f-af5f-01d39b37de9a');


-- 2. Permisos de EJECUCIÓN a la función is_creator
-- 1. Permisos de USO al esquema auth_management

-- Eliminar permisos previos (si existen)
REVOKE USAGE ON SCHEMA auth_management FROM postgres;
REVOKE EXECUTE ON FUNCTION auth_management.is_creator(uuid) FROM postgres;
REVOKE EXECUTE ON FUNCTION auth_management.is_creator(uuid) FROM service_role;
GRANT USAGE ON SCHEMA auth_management TO postgres;
GRANT EXECUTE ON FUNCTION auth_management.is_creator(uuid) TO postgres;
GRANT EXECUTE ON FUNCTION auth_management.is_creator(uuid) TO service_role;

-- O, de forma más amplia (si el Service Role Key no funciona):
-- GRANT EXECUTE ON FUNCTION auth_management.is_creator(uuid) TO authenticated;


select * from auth_management.is_universal_manager('f147d494-06f9-4e3f-af5f-01d39b37de9a');