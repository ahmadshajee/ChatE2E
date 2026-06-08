// ============================================================
//  User Types — Profile metadata synced with Supabase Auth
// ============================================================

/** User status in the system */
export enum UserStatus {
  Active = 'active',
  Suspended = 'suspended',
  Deleted = 'deleted',
}

/** Server-side user profile (extends auth.users) */
export interface UserProfile {
  /** UUID matching auth.users.id */
  id: string;
  /** Display name */
  display_name: string;
  /** Optional avatar URL */
  avatar_url: string | null;
  /** Base64-encoded X25519 identity public key */
  identity_public_key: string;
  /** Account status */
  status: UserStatus;
  /** ISO 8601 timestamp */
  created_at: string;
  /** ISO 8601 timestamp */
  updated_at: string;
}

/** Payload for creating/updating a user profile */
export interface UserProfileUpsert {
  display_name: string;
  avatar_url?: string | null;
  identity_public_key: string;
}
