// import { createClient } from "npm:@supabase/supabase-js@2.27.0";

// // Reverted: simpler initialization matching previously working version
// const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
// const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

// if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
//   console.error("Faltan claves de entorno SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY.");
//   throw new Error("Missing environment variables.");
// }

// const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
//   auth: {
//     persistSession: false
//   }
// });

// // --- Configuración de CORS (Se mantiene tu configuración) ---
// const ALLOWED_ORIGINS = [
//   'https://dev.zentoner.pages.dev',
//   'https://zentoner.pages.dev',
//   'http://localhost:4200'
// ];
// function corsHeaders(origin) {
//   const headers = {
//     'Access-Control-Allow-Methods': 'POST, OPTIONS',
//     'Access-Control-Allow-Headers': 'Content-Type, Authorization'
//   };
//   if (origin && ALLOWED_ORIGINS.includes(origin)) {
//     headers['Access-Control-Allow-Origin'] = origin;
//     headers['Access-Control-Allow-Credentials'] = 'true';
//   }
//   return headers;
// }
// console.info('user-create-with-audit function initialized (secure version)');

// // --- Función Principal ---
// Deno.serve(async (req) => {
//   const origin = req.headers.get('origin');

//   // Manejo de OPTIONS (CORS Preflight)
//   if (req.method === 'OPTIONS') {
//     const headers = corsHeaders(origin);
//     return new Response(null, { status: 204, headers });
//   }

//   const baseCors = corsHeaders(origin);
//   let actorId: string | null = null;
//   let newUserId: string | null = null;
//   let payload;

//   try {
//     if (req.method !== 'POST') {
//       return new Response('Method not allowed', { status: 405, headers: baseCors });
//     }

//     const ip = req.headers.get('x-forwarded-for') ?? req.headers.get('x-real-ip') ?? req.conn.remoteAddr?.hostname ?? 'unknown';
//     const userAgent = req.headers.get('user-agent') ?? null;

//     payload = await req.json();

//     // El payload debe coincidir con lo que envía Angular (ajustando 'authEmail' a 'email' en people, y usando 'email' para Auth)
//     const { email, password, firstName, lastName, authEmail, initialRoleNames = [] } = payload;

//     // -----------------------------------------------------------
//     // 1. VERIFICACIÓN DE PERMISOS (PASO CRÍTICO DE SEGURIDAD)
//     // -----------------------------------------------------------

//     const authHeader = req.headers.get('Authorization');
//     if (!authHeader) throw new Error('AUTH_REQUIRED: Missing Authorization token.');
//     const token = authHeader.replace('Bearer ', '');

//     // Obtener el ID del usuario logueado (el ACTOR que ejecuta la creación)
//     const { data: { user: creatorUser }, error: tokenError } = await supabaseAdmin.auth.getUser(token);
//     if (tokenError || !creatorUser) throw new Error('TOKEN_INVALID: Invalid or expired token.');

//     actorId = creatorUser.id;

//     // Llamada RPC para verificar si el actor tiene el rol 'creador'
//     const { data: isCreator, error: roleCheckError } = await supabaseAdmin.rpc('is_creator_check', { user_id: actorId });

//     if (roleCheckError || !isCreator) {
//       // Loguear intento fallido por falta de permiso
//       await supabaseAdmin.from('audit_logs').insert([{ action: 'create_user', actor_id: actorId, status: 'denied', ip, user_agent: userAgent, payload: { reason: 'No creator role', target_email: email } }]);
//       return new Response(JSON.stringify({ error: 'PERMISSION_DENIED: User lacks creator role.' }), { status: 403, headers: { 'Content-Type': 'application/json', ...baseCors } });
//     }

//     // -----------------------------------------------------------
//     // 2. CREACIÓN DEL USUARIO (Auth)
//     // -----------------------------------------------------------

//     const { data: userData, error: createError } = await supabaseAdmin.auth.admin.createUser({
//       email,
//       password,
//       user_metadata: { first_name: firstName, last_name: lastName }
//     });

//     if (createError) {
//       // Loguear fallo en la creación de Auth
//       await supabaseAdmin.from('audit_logs').insert([{ action: 'create_user', actor_id: actorId, status: 'failed', ip, user_agent: userAgent, payload: { error: createError.message, provided: { email, firstName, lastName } } }]);
//       return new Response(JSON.stringify({ error: createError.message }), { status: 400, headers: { 'Content-Type': 'application/json', ...baseCors } });
//     }

//     newUserId = userData.user?.id ?? null;
//     if (!newUserId) throw new Error("Could not retrieve new user ID.");

//     // -----------------------------------------------------------
//     // 3. CREACIÓN DE PERFILES EN DB (people y employees)
//     // -----------------------------------------------------------

//     let peopleCreated = false;
//     let employeeCreated = false;

//     // Intentar crear People (Email personal/público)
//     const { error: peopleErr } = await supabaseAdmin.from('people').insert([{
//       id: newUserId,
//       email: authEmail ?? email, // Usamos authEmail del payload o el email de auth por defecto
//       first_name: firstName ?? null,
//       last_name: lastName ?? null,
//       person_type: 'natural'
//     }]).catch(e => { console.error('People insert failed:', e); return { error: e }; });
//     if (peopleErr) {
//       // Si falla la DB, lanzamos error para que se active la limpieza.
//       throw new Error(`DB_PEOPLE_FAILED: ${peopleErr.message}`);
//     }
//     peopleCreated = true;


//     // Intentar crear Employee
//     const { error: employeeErr } = await supabaseAdmin.from('employees').insert([{
//       id: newUserId,
//       auth_email: email, // Email de Auth
//       status: 'active',
//       hire_date: new Date().toISOString().slice(0, 10)
//     }]).catch(e => { console.error('Employee insert failed:', e); return { error: e }; });
//     if (employeeErr) {
//       // Si falla la DB, lanzamos error para que se active la limpieza.
//       throw new Error(`DB_EMPLOYEE_FAILED: ${employeeErr.message}`);
//     }
//     employeeCreated = true;

//     // -----------------------------------------------------------
//     // 4. ASIGNACIÓN DE ROLES (employee_roles)
//     // -----------------------------------------------------------

//     const roleAssignmentResults = [];
//     if (initialRoleNames && initialRoleNames.length > 0) {
//       const { data: rolesData, error: rolesErr } = await supabaseAdmin.from('roles').select('id,name').in('name', initialRoleNames);

//       if (rolesErr) {
//         // Loguear error de obtención de roles, pero no fallamos toda la transacción (ya se creó el usuario).
//         console.error('Error fetching roles:', rolesErr);
//         roleAssignmentResults.push({ status: 'partial_fail', error: `Failed to fetch roles: ${rolesErr.message}` });
//       } else {
//         const roleInsertions = rolesData.map(r => ({ employee_id: newUserId, role_id: r.id }));

//         const { error: insertErr } = await supabaseAdmin.from('employee_roles').insert(roleInsertions);

//         if (insertErr) {
//           console.error('Error inserting employee_roles:', insertErr);
//           roleAssignmentResults.push({ status: 'partial_fail', error: `Failed to assign roles: ${insertErr.message}` });
//         } else {
//           roleAssignmentResults.push({ status: 'completed', roles: initialRoleNames });
//         }
//       }
//     } else {
//       roleAssignmentResults.push({ status: 'skipped', message: 'No roles provided.' });
//     }

//     // -----------------------------------------------------------
//     // 5. FINALIZACIÓN Y AUDITORÍA
//     // -----------------------------------------------------------

//     await supabaseAdmin.from('audit_logs').insert([{
//       action: 'create_user',
//       actor_id: actorId,
//       target_id: newUserId,
//       status: 'success',
//       ip,
//       user_agent: userAgent,
//       payload: { email, first_name: firstName, last_name: lastName, roleAssignmentResults }
//     }]);

//     return new Response(JSON.stringify({
//       user_id: newUserId,
//       email: email,
//       roleAssignmentResults
//     }), {
//       status: 201, // 201 Created
//       headers: { 'Content-Type': 'application/json', ...baseCors }
//     });

//   } catch (err) {
//     const errorMsg = String(err);

//     // 🚨 Lógica de Limpieza (Rollback): Si falla la DB, eliminamos el usuario de Auth.
//     if (newUserId && (errorMsg.includes('DB_PEOPLE_FAILED') || errorMsg.includes('DB_EMPLOYEE_FAILED'))) {
//       await supabaseAdmin.auth.admin.deleteUser(newUserId).catch(e => console.error("Fallo la limpieza de Auth:", e));
//     }

//     // Loguear error general
//     try {
//       await supabaseAdmin.from('audit_logs').insert([{
//         action: 'create_user',
//         actor_id: actorId,
//         target_id: newUserId,
//         status: 'failed',
//         ip: 'unknown',
//         user_agent: null,
//         payload: { error: errorMsg, provided: payload }
//       }]);
//     } catch (_) { }

//     // Determinar el código de estado basado en el error
//     let status = 500;
//     if (errorMsg.includes('AUTH_REQUIRED') || errorMsg.includes('TOKEN_INVALID')) status = 401;
//     if (errorMsg.includes('PERMISSION_DENIED')) status = 403;

//     return new Response(JSON.stringify({
//       error: errorMsg.replace(/(\w+Error: )?/, '') // Limpia prefijos de error
//     }), {
//       status: status,
//       headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) }
//     });
//   }
// });