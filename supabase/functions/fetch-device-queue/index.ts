// ============================================================
//  Edge Function: fetch-device-queue
//  Returns all pending envelopes for a device.
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req: Request) => {
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
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userClient.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }

    const body: { device_id: string; since_envelope_id?: string } = await req.json();
    if (!body.device_id) {
      return new Response(JSON.stringify({ error: "Missing device_id" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }

    // Verify device ownership
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: device } = await adminClient
      .from("devices")
      .select("id")
      .eq("id", body.device_id)
      .eq("user_id", user.id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Device not owned by user" }), {
        status: 403, headers: { "Content-Type": "application/json" },
      });
    }

    // Fetch pending envelopes
    let query = adminClient
      .from("device_envelopes")
      .select("*")
      .eq("target_device_id", body.device_id)
      .eq("status", "pending")
      .order("created_at", { ascending: true });

    const { data: envelopes, error } = await query;

    if (error) {
      return new Response(JSON.stringify({ error: "Fetch failed", details: error.message }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ envelopes: envelopes ?? [] }), {
      status: 200,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
