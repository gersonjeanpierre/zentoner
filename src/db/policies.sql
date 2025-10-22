-- ######################################################################
-- # 4. SEGURIDAD: ROW LEVEL SECURITY (RLS) OPTIMIZADA
-- ######################################################################

-- RLS Habilitadas (se mantiene)
ALTER TABLE public.people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;

-- 4.1. Políticas de Gestión de Roles y Empleados (Mantenidas)

-- Gestión de ROLES (Creación/Modificación): Solo 'super_admin'
-- Necesario para manejar la tabla 'roles' sin RPC.
DROP POLICY IF EXISTS "Super Admins can manage roles" ON public.roles;
CREATE POLICY "Super Admins can manage roles"
  ON public.roles
  FOR ALL
  TO authenticated
  USING (public.is_super_admin_check(auth.uid()))
  WITH CHECK (public.is_super_admin_check(auth.uid()));

-- Gestión de ASIGNACIÓN de ROLES: Permite a los 'creadores' asignar y quitar roles
-- Necesario para manejar la tabla 'employee_roles' sin RPC.
DROP POLICY IF EXISTS "Creators can manage all employee roles" ON public.employee_roles;
CREATE POLICY "Creators can manage all employee roles"
  ON public.employee_roles
  FOR ALL
  TO authenticated
  USING (public.is_creator_check(auth.uid()))
  WITH CHECK (public.is_creator_check(auth.uid()));

-- Gestión de DETALLES de EMPLEADOS (Status, Salario, Code)
-- Necesario para la autogestión de empleados y gestión por gestores.
DROP POLICY IF EXISTS "Manage or Own employee details" ON public.employees;
CREATE POLICY "Manage or Own employee details"
  ON public.employees
  FOR UPDATE
  TO authenticated 
  USING (
    id = auth.uid() -- Es mi propia fila
    OR public.can_manage_employees(auth.uid()) -- Soy un gestor
  )
  WITH CHECK (
    id = auth.uid()
    OR public.can_manage_employees(auth.uid())
  );

-- 4.2. Políticas de Lectura y Autogestión de Datos Personales

-- Permite que un usuario vea y ACTUALICE sus propios datos en 'people'
-- Mantenemos el UPDATE para autogestión de datos no relacionados con el estado de customer/employee.
DROP POLICY IF EXISTS "Users can view and update their own people record" ON public.people;
CREATE POLICY "Users can view and update their own people record"
  ON public.people
  FOR ALL
  TO authenticated 
  USING (id = auth.uid()) 
  WITH CHECK (id = auth.uid());

-- Permite que un usuario vea sus propios datos de empleado
DROP POLICY IF EXISTS "Users can view their own employee record" ON public.employees;
CREATE POLICY "Users can view their own employee record"
  ON public.employees
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- RLS en public.people: Lectura de clientes (Combinada y Optimizada)
-- Permite la lectura del propio registro O si el registro es parte de un cliente.
DROP POLICY IF EXISTS "Authenticated users can read their own or customer people records" ON public.people;
CREATE POLICY "Authenticated users can read their own or customer people records"
  ON public.people
  FOR SELECT
  TO authenticated
  USING (
    id = auth.uid() 
  );


-- 4.3. Políticas Específicas para CUSTOMERS (Solo Lectura)

-- RLS en public.customers (Solo LECTURA)
-- Se eliminan las políticas FOR INSERT/UPDATE ya que se usa RPC.
-- Se mantiene la política de SELECT para clientes activos.
DROP POLICY IF EXISTS "All authenticated users can select active customers" ON public.customers;
CREATE POLICY "All authenticated users can select active customers"
  ON public.customers
  FOR SELECT
  TO authenticated
  USING (
    -- Solo verán registros si el customer y la persona están activos
    is_active = TRUE 
    AND EXISTS (
        SELECT 1 
        FROM public.people p 
        WHERE p.id = customers.id AND p.deleted_at IS NULL
    )
  );
  
-- *** RLS ADICIONAL: customers_active VIEW ***
-- La vista ya filtra por activo/no borrado.
ALTER VIEW public.customers_active SET (security_barrier = true);