import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders,
    });
  }

  if (request.method !== "POST") {
    return json({ error: "Método no permitido" }, 405);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!url || !anonKey || !serviceKey) {
    return json({ error: "Configuración incompleta" }, 500);
  }

  try {
    const body = await request.json();

    const businessCode =
      typeof body.business_code === "string"
        ? body.business_code.trim().toUpperCase()
        : "";

    const username =
      typeof body.username === "string"
        ? body.username.trim().toLowerCase()
        : "";

    const password =
      typeof body.password === "string"
        ? body.password
        : "";

    if (
      !/^[A-Z0-9_-]{3,30}$/.test(businessCode) ||
      !/^[a-z0-9_]{3,30}$/.test(username) ||
      password.length === 0
    ) {
      return json({ error: "Credenciales incorrectas" }, 401);
    }

    const admin = createClient(url, serviceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: business } = await admin
      .from("businesses")
      .select("id")
      .eq("code", businessCode)
      .eq("is_active", true)
      .maybeSingle();

    if (!business) {
      return json({ error: "Credenciales incorrectas" }, 401);
    }

    const { data: member } = await admin
      .from("business_members")
      .select("user_id, role")
      .eq("business_id", business.id)
      .eq("username", username)
      .eq("is_active", true)
      .in("role", ["admin", "cashier"])
      .maybeSingle();

    if (!member) {
      return json({ error: "Credenciales incorrectas" }, 401);
    }

    const { data: userData, error: userError } =
      await admin.auth.admin.getUserById(member.user_id);

    if (userError || !userData.user?.email) {
      return json({ error: "Credenciales incorrectas" }, 401);
    }

    const auth = createClient(url, anonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: sessionData, error: loginError } =
      await auth.auth.signInWithPassword({
        email: userData.user.email,
        password,
      });

    if (loginError || !sessionData.session) {
      return json({ error: "Credenciales incorrectas" }, 401);
    }

    return json({
      access_token: sessionData.session.access_token,
      refresh_token: sessionData.session.refresh_token,
      username,
      role: member.role,
    });
  } catch {
    return json({ error: "No se pudo procesar la solicitud" }, 400);
  }
});
