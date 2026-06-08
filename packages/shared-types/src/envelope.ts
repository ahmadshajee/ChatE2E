// ============================================================
//  Envelope Types — Encrypted message routing metadata
//  NOTE: The actual message content is NEVER stored as plaintext
//  on the server. Only ciphertext blobs transit through here.
// ============================================================

/** Envelope status lifecycle */
export enum EnvelopeStatus {
  /** Stored on server, not yet fetched by target device */
  Pending = 'pending',
  /** Fetched by target device */
  Delivered = 'delivered',
  /** Target device acknowledged processing */
  Acknowledged = 'acknowledged',
}

/** Type of envelope content */
export enum EnvelopeType {
  /** Regular encrypted message */
  Message = 'message',
  /** First message in a new session (includes prekey material) */
  PrekeyMessage = 'prekey_message',
  /** Key exchange / ratchet step */
  KeyExchange = 'key_exchange',
}

/**
 * A device envelope — the server-side representation of an
 * encrypted message destined for a specific device.
 * 
 * The `ciphertext` field contains Base64-encoded encrypted data
 * that can only be decrypted by the target device's private keys.
 */
export interface DeviceEnvelope {
  /** UUID primary key */
  id: string;
  /** Which conversation this belongs to (routing only) */
  conversation_id: string;
  /** Sender's device UUID */
  sender_device_id: string;
  /** Target device UUID */
  target_device_id: string;
  /** Client-generated idempotency key */
  client_message_id: string;
  /** Base64-encoded ciphertext — NEVER plaintext */
  ciphertext: string;
  /** Type of envelope */
  envelope_type: EnvelopeType;
  /** Current delivery status */
  status: EnvelopeStatus;
  /** ISO 8601 */
  created_at: string;
  /** ISO 8601 — when this envelope should be auto-deleted */
  expires_at: string;
}

/** Payload for creating a batch of envelopes (one per target device) */
export interface EnvelopeSendBatch {
  conversation_id: string;
  client_message_id: string;
  envelope_type: EnvelopeType;
  /** One entry per target device */
  envelopes: Array<{
    target_device_id: string;
    ciphertext: string;
  }>;
}

/** Acknowledgement payload for a processed envelope */
export interface EnvelopeAck {
  envelope_id: string;
}
