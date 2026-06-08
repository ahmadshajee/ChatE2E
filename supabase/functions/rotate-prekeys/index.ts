// ============================================================
//  Edge Function: rotate-prekeys
//  Rotates the signed prekey and replenishes one-time prekeys
//  for an existing device.
// ============================================================
// Deno runtime (Supabase Edge Functions)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "YOUR_SUPABASE_URL_HERE";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE";

interface RotatePrekeysRequest {
  device_id: string;
  new_signed_prekey: {
    prekey_id: number;
    public_key: string;
    signature: string;
  };
  new_one_time_prekeys: Array<{
    prekey_id: number;
    public_key: string;
  }>;
}

serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
      },
    });
  }

  try {
    // ── 1. Validate auth ────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser(authHeader.replace("Bearer ", ""));

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 2. Parse request body ───────────────────────────────
    const body: RotatePrekeysRequest = await req.json();

    if (!body.device_id || !body.new_signed_prekey) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: device_id, new_signed_prekey" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── 3. Verify device ownership ──────────────────────────
    const { data: device, error: deviceError } = await adminClient
      .from("devices")
      .select("id, user_id")
      .eq("id", body.device_id)
      .single();

    if (deviceError || !device || device.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "Device not found or not owned by user" }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 4. Update signed prekey ─────────────────────────────
    const { error: updateError } = await adminClient
      .from("devices")
      .update({
        signed_prekey_public: body.new_signed_prekey.public_key,
        signed_prekey_signature: body.new_signed_prekey.signature,
        signed_prekey_id: body.new_signed_prekey.prekey_id,
        last_seen_at: new Date().toISOString(),
      })
      .eq("id", body.device_id);

    if (updateError) {
      console.error("Signed prekey update error:", updateError);
      return new Response(
        JSON.stringify({ error: "Failed to update signed prekey" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 5. Delete consumed one-time prekeys ─────────────────
    await adminClient
      .from("one_time_prekeys")
      .delete()
      .eq("device_id", body.device_id)
      .eq("is_consumed", true);

    // ── 6. Insert new one-time prekeys ──────────────────────
    let prekeysAdded = 0;

    if (body.new_one_time_prekeys && body.new_one_time_prekeys.length > 0) {
      const prekeyRows = body.new_one_time_prekeys.map((pk) => ({
        device_id: body.device_id,
        prekey_id: pk.prekey_id,
        public_key: pk.public_key,
        is_consumed: false,
      }));

      const { error: insertError } = await adminClient
        .from("one_time_prekeys")
        .insert(prekeyRows);

      if (insertError) {
        console.error("Prekey insert error:", insertError);
      } else {
        prekeysAdded = prekeyRows.length;
      }
    }

    // ── 7. Count remaining active prekeys ───────────────────
    const { count, error: countError } = await adminClient
      .from("one_time_prekeys")
      .select("id", { count: "exact", head: true })
      .eq("device_id", body.device_id)
      .eq("is_consumed", false);

    const totalActive = countError ? -1 : (count ?? 0);

    // ── 8. Return response ──────────────────────────────────
    return new Response(
      JSON.stringify({
        signed_prekey_updated: true,
        one_time_prekeys_added: prekeysAdded,
        total_active_prekeys: totalActive,
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
