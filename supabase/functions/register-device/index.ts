// ============================================================
//  Edge Function: register-device
//  Registers a new device for the authenticated user,
//  stores its signed prekey, and bulk-inserts one-time prekeys.
// ============================================================
// Deno runtime (Supabase Edge Functions)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "YOUR_SUPABASE_URL_HERE";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "YOUR_SUPABASE_SERVICE_ROLE_KEY_HERE";

interface RegisterDeviceRequest {
  device_type: "mobile" | "web" | "desktop";
  platform: "android" | "ios" | "web" | "windows" | "macos" | "linux";
  signed_prekey_public: string;
  signed_prekey_signature: string;
  signed_prekey_id: number;
  one_time_prekeys: Array<{
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

    // Create a client with the user's JWT to get their identity
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
    const body: RegisterDeviceRequest = await req.json();

    // Basic validation
    if (!body.device_type || !body.platform || !body.signed_prekey_public) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: device_type, platform, signed_prekey_public" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 3. Use service role client for DB operations ────────
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── 4. Insert device ────────────────────────────────────
    const { data: device, error: deviceError } = await adminClient
      .from("devices")
      .insert({
        user_id: user.id,
        device_type: body.device_type,
        platform: body.platform,
        signed_prekey_public: body.signed_prekey_public,
        signed_prekey_signature: body.signed_prekey_signature,
        signed_prekey_id: body.signed_prekey_id,
        is_active: true,
      })
      .select("id")
      .single();

    if (deviceError) {
      console.error("Device insert error:", deviceError);
      return new Response(
        JSON.stringify({ error: "Failed to register device", details: deviceError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── 5. Bulk-insert one-time prekeys ─────────────────────
    let prekeysUploaded = 0;

    if (body.one_time_prekeys && body.one_time_prekeys.length > 0) {
      const prekeyRows = body.one_time_prekeys.map((pk) => ({
        device_id: device.id,
        prekey_id: pk.prekey_id,
        public_key: pk.public_key,
        is_consumed: false,
      }));

      const { error: prekeyError } = await adminClient
        .from("one_time_prekeys")
        .insert(prekeyRows);

      if (prekeyError) {
        console.error("Prekey insert error:", prekeyError);
        // Device was created but prekeys failed — log but don't fail entirely
        // Client can retry prekey upload via rotate-prekeys
      } else {
        prekeysUploaded = prekeyRows.length;
      }
    }

    // ── 6. Initialize sync cursor for this device ───────────
    await adminClient
      .from("device_sync_cursors")
      .insert({
        device_id: device.id,
        last_envelope_id: null,
        last_synced_at: new Date().toISOString(),
      });

    // ── 7. Return response ──────────────────────────────────
    return new Response(
      JSON.stringify({
        device_id: device.id,
        prekeys_uploaded: prekeysUploaded,
      }),
      {
        status: 201,
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
