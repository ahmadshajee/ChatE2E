// ============================================================
//  Local Database (Dexie/IndexedDB)
//  Mirrors the Flutter Drift schema.
//  Plaintext messages live ONLY here — never on the server.
// ============================================================

import Dexie, { type EntityTable } from "dexie";

// ── Types ────────────────────────────────────────────────────

export interface LocalMessage {
  id: string;              // client_message_id (UUID)
  conversationId: string;
  senderId: string;
  content: string;         // PLAINTEXT
  sentAt: Date;
  status: "pending" | "sent" | "delivered" | "read" | "failed";
  isMine: boolean;
  envelopeId?: string;
}

export interface LocalConversation {
  id: string;              // server conversation UUID
  peerUserId: string;
  peerDisplayName: string;
  peerEmail: string;
  lastMessage?: string;
  lastMessageAt?: Date;
  unreadCount: number;
}

export interface OutboundQueueItem {
  id: string;
  messageId: string;
  targetDeviceId: string;
  ciphertext: string;
  envelopeType: "message" | "prekey_message" | "key_exchange";
  conversationId: string;
  createdAt: Date;
  attempts: number;
}

export interface SessionKeyEntry {
  id: string;              // {myDeviceId}:{peerDeviceId}
  peerDeviceId: string;
  sharedSecret: string;    // Base64 AES-256 key
  establishedAt: Date;
  peerIdentityKey: string;
}

export interface DeviceKeyEntry {
  keyName: string;
  keyValue: string;        // Base64 encoded key
  createdAt: Date;
}

// ── Database ─────────────────────────────────────────────────

class ChatizyDB extends Dexie {
  localMessages!: EntityTable<LocalMessage, "id">;
  localConversations!: EntityTable<LocalConversation, "id">;
  outboundQueue!: EntityTable<OutboundQueueItem, "id">;
  sessionKeys!: EntityTable<SessionKeyEntry, "id">;
  deviceKeyStore!: EntityTable<DeviceKeyEntry, "keyName">;

  constructor() {
    super("chatizy_local");

    this.version(1).stores({
      localMessages: "id, conversationId, senderId, sentAt, status",
      localConversations: "id, peerUserId, lastMessageAt",
      outboundQueue: "id, messageId, createdAt",
      sessionKeys: "id, peerDeviceId",
      deviceKeyStore: "keyName",
    });
  }
}

export const db = new ChatizyDB();

// ── Helper Functions ─────────────────────────────────────────

export async function getMessages(conversationId: string): Promise<LocalMessage[]> {
  return db.localMessages
    .where("conversationId")
    .equals(conversationId)
    .sortBy("sentAt");
}

export async function insertMessage(message: LocalMessage): Promise<void> {
  await db.localMessages.put(message);
}

export async function updateMessageStatus(id: string, status: LocalMessage["status"]): Promise<void> {
  await db.localMessages.update(id, { status });
}

export async function getConversations(): Promise<LocalConversation[]> {
  const convs = await db.localConversations.toArray();
  return convs.sort((a, b) => {
    const aTime = a.lastMessageAt?.getTime() ?? 0;
    const bTime = b.lastMessageAt?.getTime() ?? 0;
    return bTime - aTime;
  });
}

export async function upsertConversation(conv: LocalConversation): Promise<void> {
  await db.localConversations.put(conv);
}

export async function getConversation(id: string): Promise<LocalConversation | undefined> {
  return db.localConversations.get(id);
}

export async function findConversationByPeer(peerUserId: string): Promise<LocalConversation | undefined> {
  return db.localConversations.where("peerUserId").equals(peerUserId).first();
}

export async function storeSessionKey(entry: SessionKeyEntry): Promise<void> {
  await db.sessionKeys.put(entry);
}

export async function getSessionKey(myDeviceId: string, peerDeviceId: string): Promise<SessionKeyEntry | undefined> {
  return db.sessionKeys.get(`${myDeviceId}:${peerDeviceId}`);
}

export async function storeDeviceKey(name: string, value: string): Promise<void> {
  await db.deviceKeyStore.put({ keyName: name, keyValue: value, createdAt: new Date() });
}

export async function getDeviceKey(name: string): Promise<string | undefined> {
  const entry = await db.deviceKeyStore.get(name);
  return entry?.keyValue;
}
