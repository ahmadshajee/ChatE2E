// ============================================================
//  Web Message Service
//  Handles sending/receiving encrypted envelopes.
// ============================================================

import { createClient } from "@/lib/supabase/client";
import { encrypt, decrypt, generateRandomKey } from "@/lib/crypto/message-crypto";
import {
  insertMessage,
  updateMessageStatus,
  getMessages as getLocalMessages,
  upsertConversation,
  getConversation,
  storeSessionKey,
  getSessionKey,
  type LocalMessage,
} from "@/lib/db/local-db";

export async function sendMessage(
  conversationId: string,
  content: string,
  myDeviceId: string
): Promise<void> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  const messageId = crypto.randomUUID();
  const now = new Date();

  // 1. Store plaintext locally
  await insertMessage({
    id: messageId,
    conversationId,
    senderId: user.id,
    content,
    sentAt: now,
    status: "pending",
    isMine: true,
  });

  // Update conversation
  const conv = await getConversation(conversationId);
  if (conv) {
    await upsertConversation({
      ...conv,
      lastMessage: content,
      lastMessageAt: now,
    });
  }

  try {
    // 2. Find peer devices
    const { data: members } = await supabase
      .from("conversation_members")
      .select("user_id")
      .eq("conversation_id", conversationId)
      .neq("user_id", user.id);

    const peerIds = (members ?? []).map((m: any) => m.user_id);
    if (!peerIds.length) {
      await updateMessageStatus(messageId, "failed");
      return;
    }

    const { data: devices } = await supabase
      .from("devices")
      .select("id, user_id")
      .in("user_id", peerIds)
      .eq("is_active", true);

    if (!(devices ?? []).length) {
      await updateMessageStatus(messageId, "failed");
      return;
    }

    // 3. For each device, get or create session key and encrypt
    for (const device of devices!) {
      let session = await getSessionKey(myDeviceId, device.id);
      let sharedSecret: string;
      let envelopeType: string = "message";

      if (!session) {
        // Generate a simple shared key for now
        // Full X3DH implemented on Flutter side; web uses simplified key exchange
        sharedSecret = await generateRandomKey();
        await storeSessionKey({
          id: `${myDeviceId}:${device.id}`,
          peerDeviceId: device.id,
          sharedSecret,
          establishedAt: new Date(),
          peerIdentityKey: "",
        });
        envelopeType = "prekey_message";
      } else {
        sharedSecret = session.sharedSecret;
      }

      // Encrypt
      const ciphertext = await encrypt(content, sharedSecret);

      const envelopePayload = btoa(
        JSON.stringify({
          ciphertext,
          client_message_id: messageId,
          ...(envelopeType === "prekey_message"
            ? { header: { shared_key: sharedSecret } }
            : {}),
        })
      );

      // Insert on server
      await supabase.from("device_envelopes").insert({
        conversation_id: conversationId,
        sender_device_id: myDeviceId,
        target_device_id: device.id,
        client_message_id: messageId,
        ciphertext: envelopePayload,
        envelope_type: envelopeType,
        status: "pending",
      });
    }

    await updateMessageStatus(messageId, "sent");
  } catch (e) {
    console.error("Send error:", e);
    await updateMessageStatus(messageId, "failed");
  }
}

export async function processEnvelope(
  envelope: any,
  myDeviceId: string
): Promise<void> {
  try {
    const envelopeId = envelope.id;
    const conversationId = envelope.conversation_id;
    const senderDeviceId = envelope.sender_device_id;
    const envelopeType = envelope.envelope_type;
    const rawCiphertext = envelope.ciphertext;
    const clientMessageId = envelope.client_message_id;

    // Decode payload
    const payloadStr = atob(rawCiphertext);
    const payload = JSON.parse(payloadStr);
    const ciphertext = payload.ciphertext;

    // Get session key
    let session = await getSessionKey(myDeviceId, senderDeviceId);
    let sharedSecret: string;

    if (!session && envelopeType === "prekey_message" && payload.header?.shared_key) {
      // Store the shared key from the prekey message
      sharedSecret = payload.header.shared_key;
      await storeSessionKey({
        id: `${myDeviceId}:${senderDeviceId}`,
        peerDeviceId: senderDeviceId,
        sharedSecret,
        establishedAt: new Date(),
        peerIdentityKey: "",
      });
    } else if (session) {
      sharedSecret = session.sharedSecret;
    } else {
      console.error("No session key for device", senderDeviceId);
      return;
    }

    // Decrypt
    const plaintext = await decrypt(ciphertext, sharedSecret);

    // Get sender info
    const supabase = createClient();
    const { data: deviceData } = await supabase
      .from("devices")
      .select("user_id")
      .eq("id", senderDeviceId)
      .maybeSingle();

    // Store plaintext locally
    await insertMessage({
      id: clientMessageId,
      conversationId,
      senderId: deviceData?.user_id ?? "unknown",
      content: plaintext,
      sentAt: new Date(),
      status: "delivered",
      isMine: false,
      envelopeId,
    });

    // Update conversation
    const conv = await getConversation(conversationId);
    if (conv) {
      await upsertConversation({
        ...conv,
        lastMessage: plaintext,
        lastMessageAt: new Date(),
        unreadCount: (conv.unreadCount ?? 0) + 1,
      });
    }

    // Ack envelope
    await supabase
      .from("device_envelopes")
      .update({ status: "delivered" })
      .eq("id", envelopeId);
  } catch (e) {
    console.error("Process envelope error:", e);
  }
}

export async function catchUp(myDeviceId: string): Promise<void> {
  try {
    const supabase = createClient();
    const { data: envelopes } = await supabase
      .from("device_envelopes")
      .select("*")
      .eq("target_device_id", myDeviceId)
      .eq("status", "pending")
      .order("created_at");

    for (const env of envelopes ?? []) {
      await processEnvelope(env, myDeviceId);
    }
  } catch (e) {
    console.error("Catch-up error:", e);
  }
}

export { getLocalMessages };
