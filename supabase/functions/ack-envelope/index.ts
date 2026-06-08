// ============================================================
//  Edge Function: ack-envelope
//  Acknowledges receipt of an envelope (marks it delivered).
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

    const body: { envelope_id: string; status: "delivered" | "acknowledged" } = await req.json();
    if (!body.envelope_id || !body.status) {
      return new Response(JSON.stringify({ error: "Missing envelope_id or status" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Verify the envelope targets a device owned by this user
    const { data: envelope } = await adminClient
      .from("device_envelopes")
      .select("id, target_device_id")
      .eq("id", body.envelope_id)
      .single();

    if (!envelope) {
      return new Response(JSON.stringify({ error: "Envelope not found" }), {
        status: 404, headers: { "Content-Type": "application/json" },
      });
    }

    const { data: device } = await adminClient
      .from("devices")
      .select("id")
      .eq("id", envelope.target_device_id)
      .eq("user_id", user.id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Not authorized to ack this envelope" }), {
        status: 403, headers: { "Content-Type": "application/json" },
      });
    }

    // Update envelope status
    await adminClient
      .from("device_envelopes")
      .update({ status: body.status })
      .eq("id", body.envelope_id);

    // Insert delivery event
    await adminClient.from("delivery_events").insert({
      envelope_id: body.envelope_id,
      device_id: envelope.target_device_id,
      event_type: body.status === "delivered" ? "delivered" : "delivered",
    });

    return new Response(JSON.stringify({ success: true }), {
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
