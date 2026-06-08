// ============================================================
//  Web Conversation Service
//  Creates and fetches direct conversations.
// ============================================================

import { createClient } from "@/lib/supabase/client";
import {
  upsertConversation,
  findConversationByPeer,
  getConversations as getLocalConversations,
  getConversation as getLocalConversation,
  type LocalConversation,
} from "@/lib/db/local-db";
import type { Contact } from "./contact-service";

export async function getOrCreateDirectConversation(
  peer: Contact
): Promise<string> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new Error("Not authenticated");

  // 1. Check local DB
  const local = await findConversationByPeer(peer.id);
  if (local) return local.id;

  // 2. Check server for existing conversation
  const existingId = await findExistingConversation(
    supabase,
    user.id,
    peer.id
  );
  if (existingId) {
    await upsertConversation({
      id: existingId,
      peerUserId: peer.id,
      peerDisplayName: peer.displayName,
      peerEmail: peer.email ?? "",
      unreadCount: 0,
    });
    return existingId;
  }

  // 3. Create new conversation
  const { data: conv } = await supabase
    .from("conversations")
    .insert({ type: "direct", created_by: user.id })
    .select("id")
    .single();

  if (!conv) throw new Error("Failed to create conversation");

  await supabase.from("conversation_members").insert([
    { conversation_id: conv.id, user_id: user.id, role: "admin" },
    { conversation_id: conv.id, user_id: peer.id, role: "member" },
  ]);

  await upsertConversation({
    id: conv.id,
    peerUserId: peer.id,
    peerDisplayName: peer.displayName,
    peerEmail: peer.email ?? "",
    unreadCount: 0,
  });

  return conv.id;
}

async function findExistingConversation(
  supabase: any,
  userId: string,
  peerId: string
): Promise<string | null> {
  try {
    const { data: myConvs } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq("user_id", userId)
      .is("left_at", null);

    const myIds = (myConvs ?? []).map((r: any) => r.conversation_id);
    if (!myIds.length) return null;

    const { data: shared } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq("user_id", peerId)
      .is("left_at", null)
      .in("conversation_id", myIds);

    if (!(shared ?? []).length) return null;

    const { data: conv } = await supabase
      .from("conversations")
      .select("id")
      .eq("id", shared[0].conversation_id)
      .eq("type", "direct")
      .maybeSingle();

    return conv?.id ?? null;
  } catch {
    return null;
  }
}

export async function syncConversations(): Promise<void> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return;

  try {
    const { data: memberships } = await supabase
      .from("conversation_members")
      .select("conversation_id")
      .eq("user_id", user.id)
      .is("left_at", null);

    const convIds = (memberships ?? []).map((r: any) => r.conversation_id);
    if (!convIds.length) return;

    for (const convId of convIds) {
      const { data: members } = await supabase
        .from("conversation_members")
        .select("user_id")
        .eq("conversation_id", convId)
        .neq("user_id", user.id);

      const membersList = members ?? [];
      if (!membersList.length) continue;

      const peerId = membersList[0].user_id;
      const { data: peerData } = await supabase
        .from("users")
        .select("id, display_name, avatar_url")
        .eq("id", peerId)
        .single();

      if (!peerData) continue;

      const existing = await getLocalConversation(convId);

      await upsertConversation({
        id: convId,
        peerUserId: peerId,
        peerDisplayName: peerData.display_name ?? "User",
        peerEmail: "",
        lastMessage: existing?.lastMessage,
        lastMessageAt: existing?.lastMessageAt,
        unreadCount: existing?.unreadCount ?? 0,
      });
    }
  } catch (e) {
    console.error("Conversation sync error:", e);
  }
}

export { getLocalConversations as getConversations };
