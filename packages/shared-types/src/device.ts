// ============================================================
//  Device Types — Per-device identity in the E2EE system
// ============================================================

/** Physical device type categories */
export enum DeviceType {
  Mobile = 'mobile',
  Web = 'web',
  Desktop = 'desktop',
}

/** Platform identifiers */
export enum DevicePlatform {
  Android = 'android',
  iOS = 'ios',
  Web = 'web',
  Windows = 'windows',
  MacOS = 'macos',
  Linux = 'linux',
}

/** A registered device in the system */
export interface Device {
  /** UUID primary key */
  id: string;
  /** Owning user's UUID */
  user_id: string;
  /** Device type category */
  device_type: DeviceType;
  /** Specific platform */
  platform: DevicePlatform;
  /** FCM/APNs push token (nullable, set later) */
  push_token: string | null;
  /** Base64-encoded signed prekey public part */
  signed_prekey_public: string;
  /** Base64-encoded signature of the signed prekey */
  signed_prekey_signature: string;
  /** Monotonically increasing prekey ID */
  signed_prekey_id: number;
  /** Whether this device is currently active */
  is_active: boolean;
  /** ISO 8601 */
  created_at: string;
  /** ISO 8601 */
  last_seen_at: string;
}

/** Payload for registering a new device */
export interface DeviceRegistration {
  device_type: DeviceType;
  platform: DevicePlatform;
  signed_prekey_public: string;
  signed_prekey_signature: string;
  signed_prekey_id: number;
  /** Batch of initial one-time prekeys */
  one_time_prekeys: OneTimePrekeyUpload[];
}

/** A single one-time prekey to upload */
export interface OneTimePrekeyUpload {
  prekey_id: number;
  public_key: string;
}

/** Response from register-device Edge Function */
export interface DeviceRegistrationResponse {
  device_id: string;
  prekeys_uploaded: number;
}
