
import { createClient } from "npm:@supabase/supabase-js@2";

// Configuración CORS para Flutter Web.
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });

  async function hashIdentifier(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);

  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

Deno.serve(async (req) => {
  // Permitir solicitudes preflight del navegador.
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (req.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    return json({ error: "Configuración incompleta" }, 500);
  }

  // Obtener el token JWT del usuario autenticado.
  const token = req.headers
    .get("Authorization")
    ?.replace(/^Bearer\s+/i, "");

  if (!token) {
    return json({ error: "No autorizado" }, 401);
  }

  // Cliente público para verificar identidad.
  const authClient = createClient(
    supabaseUrl,
    publishableKey,
  );

  // Cliente administrativo exclusivo del servidor.
  const adminClient = createClient(
    supabaseUrl,
    serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    },
  );

 const { data: globalAllowed, error: globalError } =
  await admin.rpc("check_employee_login_global_rate");

if (globalError) {
  console.error("Error del límite global:", globalError.message);

  return json(
    { error: "No se pudo verificar el acceso" },
    500,
  );
}

if (globalAllowed !== true) {
  return json(
    { error: "Servicio temporalmente ocupado. Intenta más tarde." },
    429,
  );
} 

  const identifierHash = await hashIdentifier(
  `${businessCode}:${username}`,
);

const { data: rateAllowed, error: rateError } =
  await admin.rpc("check_employee_login_rate", {
    p_identifier_hash: identifierHash,
  });

if (rateError) {
  console.error("Error de límite de acceso:", rateError.message);

  return json(
    { error: "No se pudo verificar el acceso" },
    500,
  );
}

if (rateAllowed !== true) {
  return json(
    { error: "Demasiados intentos. Espera 15 minutos." },
    429,
  );
}

  const { data: authData, error: authError } =
    await authClient.auth.getUser(token);

  if (authError || !authData.user) {
    return json({ error: "Sesión inválida" }, 401);
  }

  try {
    const body = await req.json();

    if (
      !body ||
      typeof body !== "object" ||
      Array.isArray(body)
    ) {
      return json({ error: "Solicitud inválida" }, 400);
    }

    const businessId = body.business_id;

    const username =
      typeof body.username === "string"
        ? body.username.trim().toLowerCase()
        : "";

    const password =
      typeof body.password === "string"
        ? body.password
        : "";

    const role =
      typeof body.role === "string"
        ? body.role
        : "cashier";

    // Validación de los datos recibidos.
    if (
      !Number.isSafeInteger(businessId) ||
      businessId <= 0 ||
      !/^[a-z0-9_]{3,30}$/.test(username) ||
      password.length < 12 ||
      !["admin", "cashier"].includes(role)
    ) {
      return json({ error: "Datos inválidos" }, 400);
    }

    // Verificar que el solicitante sea propietario.
    const {
      data: membership,
      error: membershipError,
    } = await adminClient
      .from("business_members")
      .select("role")
      .eq("business_id", businessId)
      .eq("user_id", authData.user.id)
      .eq("is_active", true)
      .single();

    if (
      membershipError ||
      !membership ||
      membership.role !== "owner"
    ) {
      return json(
        { error: "Permisos insuficientes" },
        403,
      );
    }

    // Comprobar que el negocio siga activo.
    const {
      data: business,
      error: businessError,
    } = await adminClient
      .from("businesses")
      .select("id, is_active")
      .eq("id", businessId)
      .single();

    if (
      businessError ||
      !business ||
      !business.is_active
    ) {
      return json(
        { error: "Negocio inactivo o inexistente" },
        403,
      );
    }

    // Comprobar disponibilidad del nombre de usuario.
    const {
      data: existing,
      error: existingError,
    } = await adminClient
      .from("business_members")
      .select("id")
      .eq("business_id", businessId)
      .eq("username", username)
      .maybeSingle();

    if (existingError) {
      return json(
        { error: "No se pudo verificar el usuario" },
        500,
      );
    }

    if (existing) {
      return json(
        { error: "Nombre de usuario ocupado" },
        409,
      );
    }
// Límite provisional de empleados por negocio.
const { count, error: countError } = await adminClient
  .from("business_members")
  .select("id", { count: "exact", head: true })
  .eq("business_id", businessId)
  .in("role", ["admin", "cashier"]);

if (countError) {
  return json(
    { error: "No se pudo verificar el límite de empleados" },
    500,
  );
}

if ((count ?? 0) >= 20) {
  return json(
    { error: "Se alcanzó el límite de empleados" },
    409,
  );
}


    // Aplicar el límite de 5 intentos por hora.
    const { data: rateAllowed, error: rateError } =
      await adminClient.rpc("check_employee_creation_rate", {
        p_business_id: businessId,
        p_requester_id: authData.user.id,
      });

    if (rateError) {
      console.error(
        "Error al comprobar el límite de intentos:",
        rateError.message,
      );

      return json(
        { error: "No se pudo verificar el límite de solicitudes" },
        500,
      );
    }

    if (rateAllowed !== true) {
      return json(
        {
          error:
            "Límite de solicitudes alcanzado o permisos insuficientes",
        },
        429,
      );
    }


    // Generar un correo interno para Supabase Auth.
    // El empleado no necesita proporcionar correo personal.
    const internalEmail =
      `employee-${crypto.randomUUID()}@users.invalid`;

    // Crear la identidad de autenticación.
    const {
      data: created,
      error: createError,
    } = await adminClient.auth.admin.createUser({
      email: internalEmail,
      password,
      email_confirm: true,
    });

    if (createError || !created.user) {
      return json(
        { error: "No se pudo crear la cuenta" },
        500,
      );
    }

    // Registrar al empleado en el negocio.
    const { error: insertError } = await adminClient.rpc(
  "register_business_employee",
  {
    p_business_id: businessId,
    p_owner_id: authData.user.id,
    p_employee_id: created.user.id,
    p_username: username,
    p_role: role,
  },
);

    if (insertError) {
      // Intentar eliminar la identidad si falla la membresía.
      const { error: cleanupError } =
        await adminClient.auth.admin.deleteUser(
          created.user.id,
        );

      if (cleanupError) {
        console.error(
          "No se pudo limpiar la cuenta:",
          created.user.id,
          cleanupError.message,
        );

        return json(
          { error: "Error al registrar empleado; requiere revisión" },
          500,
        );
      }

      if (insertError.code === "23505") {
        return json(
          { error: "Nombre de usuario ocupado" },
          409,
        );
      }

      return json(
        { error: "No se pudo registrar al empleado" },
        500,
      );
    }

    // Responder sin revelar contraseña ni correo interno.
    return json(
      {
        success: true,
        employee: {
          id: created.user.id,
          username,
          role,
          business_id: businessId,
        },
      },
      201,
    );
  } catch (error) {
    console.error("Error en create-employee:", error);

    return json(
      { error: "No se pudo procesar la solicitud" },
      400,
    );
  }
});
