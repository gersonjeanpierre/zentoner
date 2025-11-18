-- Test data for customers - Direct INSERT approach for testing
-- This file contains 10 test customer records inserted directly into tables
-- Bypasses authentication for testing purposes

-- Test user ID for created_by_id and actor_id (use a test UUID)
DO $$
DECLARE
    test_user_id uuid := 'f147d494-06f9-4e3f-af5f-01d39b37de9a'::uuid; -- Using the same ID from tables.sql
BEGIN

-- Customer 1: Natural person - New customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'Juan', 'Pérez', NULL, 'juan.perez@email.com', '+595981234567',
    '12345678', NULL, NULL, 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440001'::uuid,
    'CUST001', 'NUEVO', '{"notes": "Cliente nuevo, interesado en impresiones láser"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440001'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST001', 'customer_type_code', 'NUEVO')
);

-- Customer 2: Natural person - Frequent customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'María', 'González', NULL, 'maria.gonzalez@email.com', '+595982345678',
    '87654321', NULL, NULL, 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440002'::uuid,
    'CUST002', 'FRECUENTE', '{"notes": "Cliente frecuente, prefiere entregas rápidas"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440002'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST002', 'customer_type_code', 'FRECUENTE')
);

-- Customer 3: Juridical person - New printer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    NULL, NULL, 'Imprenta Rápida S.A.', 'contacto@imprentarapida.com', '+595983456789',
    NULL, '80012345671', NULL, 'JURIDICA'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440003'::uuid,
    'CUST003', 'IMPRENTERO_NUEVO', '{"notes": "Nueva imprenta, necesitan cotización para equipos"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440003'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST003', 'customer_type_code', 'IMPRENTERO_NUEVO')
);

-- Customer 4: Natural person - Foreign customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440004'::uuid,
    'John', 'Smith', NULL, 'john.smith@email.com', '+595984567890',
    NULL, NULL, 'ABC123456', 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440004'::uuid,
    'CUST004', 'NUEVO', '{"notes": "Cliente extranjero, requiere factura en inglés"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440004'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST004', 'customer_type_code', 'NUEVO')
);

-- Customer 5: Juridical person - Frequent printer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440005'::uuid,
    NULL, NULL, 'Diseños Creativos Ltda.', 'ventas@disenoscreativos.com', '+595985678901',
    NULL, '80023456782', NULL, 'JURIDICA'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440005'::uuid,
    'CUST005', 'IMPRENTERO_FRECUENTE', '{"notes": "Cliente habitual, descuento por volumen aplicado"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440005'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST005', 'customer_type_code', 'IMPRENTERO_FRECUENTE')
);

-- Customer 6: Natural person - New customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440006'::uuid,
    'Carlos', 'Rodríguez', NULL, 'carlos.rodriguez@email.com', '+595986789012',
    '11223344', NULL, NULL, 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440006'::uuid,
    'CUST006', 'NUEVO', '{"notes": "Cliente nuevo, primera visita"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440006'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST006', 'customer_type_code', 'NUEVO')
);

-- Customer 7: Natural person - Frequent customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440007'::uuid,
    'Ana', 'Martínez', NULL, 'ana.martinez@email.com', '+595987890123',
    '44332211', NULL, NULL, 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440007'::uuid,
    'CUST007', 'FRECUENTE', '{"notes": "Cliente frecuente, pedidos mensuales"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440007'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST007', 'customer_type_code', 'FRECUENTE')
);

-- Customer 8: Juridical person - New printer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440008'::uuid,
    NULL, NULL, 'Gráfica Moderna S.R.L.', 'info@graficamoderna.com', '+595988901234',
    NULL, '80034567893', NULL, 'JURIDICA'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440008'::uuid,
    'CUST008', 'IMPRENTERO_NUEVO', '{"notes": "Nueva gráfica, interesada en tecnología láser"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440008'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST008', 'customer_type_code', 'IMPRENTERO_NUEVO')
);

-- Customer 9: Natural person - New customer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440009'::uuid,
    'Luis', 'Fernández', NULL, 'luis.fernandez@email.com', '+595989012345',
    '55667788', NULL, NULL, 'NATURAL'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440009'::uuid,
    'CUST009', 'NUEVO', '{"notes": "Cliente nuevo, referido por amigo"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440009'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST009', 'customer_type_code', 'NUEVO')
);

-- Customer 10: Juridical person - Frequent printer
INSERT INTO core.persons (
    id, first_name, last_name, legal_name, email, phone, dni, ruc, ce, person_type, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440010'::uuid,
    NULL, NULL, 'Impresiones Digitales C.A.', 'contacto@impresionesdigitales.com', '+595990123456',
    NULL, '80045678904', NULL, 'JURIDICA'::public.person_type_enum, test_user_id
);

INSERT INTO sales.customers (
    id, customer_code, customer_type_code, notes, created_by_id
) VALUES (
    '550e8400-e29b-41d4-a716-446655440010'::uuid,
    'CUST010', 'IMPRENTERO_FRECUENTE', '{"notes": "Cliente premium, contratos anuales"}'::jsonb, test_user_id
);

INSERT INTO core.audit_logs (
    action, actor_id, target_table, target_id, status, payload
) VALUES (
    'create_customer', test_user_id, 'sales.customers',
    '550e8400-e29b-41d4-a716-446655440010'::uuid, 'SUCCESS',
    jsonb_build_object('customer_code', 'CUST010', 'customer_type_code', 'IMPRENTERO_FRECUENTE')
);

RAISE NOTICE '✅ 10 test customers inserted successfully!';

END $$;