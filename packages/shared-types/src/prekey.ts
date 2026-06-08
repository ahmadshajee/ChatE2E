// ============================================================
//  Prekey Bundle Types — For X3DH key agreement protocol
// ============================================================

/** A signed prekey (rotated periodically) */
export interface SignedPrekey {
  /** Monotonically increasing ID */
  prekey_id: number;
  /** Base64-encoded X25519 public key */
  public_key: string;
  /** Base64-encoded Ed25519 signature over the public key */
  signature: string;
}

/** A one-time prekey (consumed on session init) */
export interface OneTimePrekey {
  /** Unique ID for this prekey */
  prekey_id: number;
  /** Base64-encoded X25519 public key */
  public_key: string;
  /** Whether this prekey has been consumed by a session init */
  is_consumed: boolean;
}

/**
 * A complete prekey bundle fetched for a target device
 * to initiate an encrypted session (X3DH).
 */
export interface PrekeyBundle {
  /** Target device UUID */
  device_id: string;
  /** Target user UUID */
  user_id: string;
  /** Base64-encoded identity public key of the target user */
  identity_public_key: string;
  /** The target device's current signed prekey */
  signed_prekey: SignedPrekey;
  /** An available one-time prekey (may be null if exhausted) */
  one_time_prekey: OneTimePrekey | null;
}

/** Payload for rotating prekeys on a device */
export interface PrekeyRotationRequest {
  device_id: string;
  /** New signed prekey to replace the current one */
  new_signed_prekey: SignedPrekey;
  /** Fresh batch of one-time prekeys to add */
  new_one_time_prekeys: Array<{
    prekey_id: number;
    public_key: string;
  }>;
}

/** Response from rotate-prekeys Edge Function */
export interface PrekeyRotationResponse {
  signed_prekey_updated: boolean;
  one_time_prekeys_added: number;
  total_active_prekeys: number;
}
