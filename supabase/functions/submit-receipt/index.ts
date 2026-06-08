// ============================================================
//  Edge Function: submit-receipt
//  Submits delivery/read/played receipts.
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

    const body: {
      envelope_id: string;
      event_type: "delivered" | "read" | "played";
    } = await req.json();

    if (!body.envelope_id || !body.event_type) {
      return new Response(JSON.stringify({ error: "Missing envelope_id or event_type" }), {
        status: 400, headers: { "Content-Type": "application/json" },
      });
    }

    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Get user's device
    const { data: device } = await adminClient
      .from("devices")
      .select("id")
      .eq("user_id", user.id)
      .eq("is_active", true)
      .limit(1)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "No active device found" }), {
        status: 404, headers: { "Content-Type": "application/json" },
      });
    }

    // Insert delivery event (upsert to avoid duplicates)
    const { error: insertError } = await adminClient
      .from("delivery_events")
      .upsert({
        envelope_id: body.envelope_id,
        device_id: device.id,
        event_type: body.event_type,
      }, {
        onConflict: "envelope_id,device_id,event_type",
      });

    if (insertError) {
      return new Response(JSON.stringify({ error: "Insert failed", details: insertError.message }), {
        status: 500, headers: { "Content-Type": "application/json" },
      });
    }

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
