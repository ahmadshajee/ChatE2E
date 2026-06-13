// ============================================================
//  Edge Function: send-envelopes-batch
//  Accepts an array of encrypted envelopes, bulk-inserts them
//  into device_envelopes, then sends FCM push notifications
//  to each target device.
// ============================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const FCM_SERVER_KEY = Deno.env.get("FCM_SERVER_KEY") ?? "";

interface EnvelopeInput {
  target_device_id: string;
  conversation_id: string;
  client_message_id: string;
  ciphertext: string;
  envelope_type: "message" | "prekey_message" | "key_exchange";
}

/**
 * Send FCM push notification to a device using legacy HTTP API.
 * Uses FCM_SERVER_KEY env var (Firebase Cloud Messaging server key).
 */
async function sendPushNotification(
  pushToken: string,
  senderName: string,
  conversationId: string
): Promise<void> {
  if (!FCM_SERVER_KEY || !pushToken) return;

  try {
    const response = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `key=${FCM_SERVER_KEY}`,
      },
      body: JSON.stringify({
        to: pushToken,
        notification: {
          title: senderName,
          body: "Sent you a message",
          sound: "default",
          badge: "1",
        },
        data: {
          conversation_id: conversationId,
          sender_name: senderName,
          type: "new_message",
        },
        priority: "high",
        content_available: true, // iOS background wake
      }),
    });

    if (!response.ok) {
      console.error("[FCM] Push failed:", response.status, await response.text());
    } else {
      console.log("[FCM] Push sent to token:", pushToken.substring(0, 20) + "...");
    }
  } catch (err) {
    console.error("[FCM] Push error:", err);
  }
}

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
    // 1. Validate auth
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
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
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 2. Parse body
    const body: { sender_device_id: string; envelopes: EnvelopeInput[] } = await req.json();

    if (!body.sender_device_id || !body.envelopes || !body.envelopes.length) {
      return new Response(JSON.stringify({ error: "Missing sender_device_id or envelopes" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 3. Verify sender device ownership
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: device } = await adminClient
      .from("devices")
      .select("id, user_id")
      .eq("id", body.sender_device_id)
      .eq("user_id", user.id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Sender device not owned by user" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 4. Bulk insert envelopes
    const rows = body.envelopes.map((env) => ({
      conversation_id: env.conversation_id,
      sender_device_id: body.sender_device_id,
      target_device_id: env.target_device_id,
      client_message_id: env.client_message_id,
      ciphertext: env.ciphertext,
      envelope_type: env.envelope_type,
      status: "pending",
    }));

    const { data: inserted, error: insertError } = await adminClient
      .from("device_envelopes")
      .insert(rows)
      .select("id");

    if (insertError) {
      return new Response(JSON.stringify({ error: "Insert failed", details: insertError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // ── 5. Send push notifications to target devices ──────────
    // Look up sender's display name
    const { data: senderUser } = await adminClient
      .from("users")
      .select("display_name")
      .eq("id", user.id)
      .single();

    const senderName = senderUser?.display_name ?? "Someone";

    // Collect unique target device IDs
    const targetDeviceIds = [...new Set(body.envelopes.map((e) => e.target_device_id))];

    // Look up push tokens for target devices
    const { data: targetDevices } = await adminClient
      .from("devices")
      .select("id, push_token")
      .in("id", targetDeviceIds)
      .eq("is_active", true);

    // Send push to each target device that has a token
    if (targetDevices && FCM_SERVER_KEY) {
      const pushPromises = targetDevices
        .filter((d: any) => d.push_token)
        .map((d: any) => {
          // Find the conversation_id for this device's envelope
          const envelope = body.envelopes.find((e) => e.target_device_id === d.id);
          return sendPushNotification(
            d.push_token,
            senderName,
            envelope?.conversation_id ?? ""
          );
        });

      // Fire-and-forget — don't block the response on push delivery
      Promise.allSettled(pushPromises).catch((err) =>
        console.error("[FCM] Batch push error:", err)
      );
    }

    return new Response(JSON.stringify({
      inserted: inserted?.length ?? 0,
      envelope_ids: inserted?.map((e: any) => e.id) ?? [],
    }), {
      status: 201,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
