// ============================================================
//  Conversation Types — Server-side routing metadata only
//  NOTE: No message content, no previews, no names stored
//  on the server. All readable data is client-side only.
// ============================================================

/** Conversation type */
export enum ConversationType {
  Direct = 'direct',
  Group = 'group',
}

/** Member role within a conversation */
export enum MemberRole {
  Admin = 'admin',
  Member = 'member',
}

/** Server-side conversation metadata (routing only) */
export interface Conversation {
  /** UUID primary key */
  id: string;
  /** Direct or group */
  type: ConversationType;
  /** User who created this conversation */
  created_by: string;
  /** ISO 8601 */
  created_at: string;
  /** ISO 8601 */
  updated_at: string;
}

/** A membership record linking a user to a conversation */
export interface ConversationMember {
  /** UUID primary key */
  id: string;
  /** Conversation UUID */
  conversation_id: string;
  /** User UUID */
  user_id: string;
  /** Role in this conversation */
  role: MemberRole;
  /** ISO 8601 */
  joined_at: string;
  /** ISO 8601, null if still active */
  left_at: string | null;
}

/** Payload for creating a new direct conversation */
export interface CreateDirectConversation {
  /** The other user's UUID */
  target_user_id: string;
}

/** Payload for creating a new group conversation */
export interface CreateGroupConversation {
  /** Initial member UUIDs (creator is auto-added as admin) */
  member_ids: string[];
}
