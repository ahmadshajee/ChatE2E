// ============================================================
//  Device Registration Service
//  Generates a device ID, stores it locally, and registers
//  the device with the server via the register-device Edge Function.
// ============================================================

import { createClient } from "@/lib/supabase/client";
import { v4 as uuidv4 } from "uuid";

const DEVICE_ID_KEY = "chatizy_device_id";
const DEVICE_REGISTERED_KEY = "chatizy_device_registered";

/** Get or generate a persistent device ID for this browser */
export function getOrCreateDeviceId(): string {
  if (typeof window === "undefined") return "";

  let deviceId = localStorage.getItem(DEVICE_ID_KEY);
  if (!deviceId) {
    deviceId = uuidv4();
    localStorage.setItem(DEVICE_ID_KEY, deviceId);
  }
  return deviceId;
}

/** Check if this device has already been registered with the server */
export function isDeviceRegistered(): boolean {
  if (typeof window === "undefined") return false;
  return localStorage.getItem(DEVICE_REGISTERED_KEY) === "true";
}

/** Get the browser platform */
function detectPlatform(): "web" | "windows" | "macos" | "linux" {
  if (typeof navigator === "undefined") return "web";
  const ua = navigator.userAgent.toLowerCase();
  if (ua.includes("win")) return "windows";
  if (ua.includes("mac")) return "macos";
  if (ua.includes("linux")) return "linux";
  return "web";
}

/**
 * Register this device with the server.
 * 
 * NOTE: In Part 1, we use placeholder prekey values.
 * Real crypto key generation will be implemented in Part 2.
 */
export async function registerDevice(): Promise<{
  success: boolean;
  deviceId?: string;
  error?: string;
}> {
  try {
    const supabase = createClient();

    // Get the current session for the auth token
    const {
      data: { session },
      error: sessionError,
    } = await supabase.auth.getSession();

    if (sessionError || !session) {
      return { success: false, error: "Not authenticated" };
    }

    // ── Placeholder prekey values ───────────────────────────
    // Real X25519/Ed25519 key generation is deferred to Part 2.
    // These are just placeholder base64 strings for schema validation.
    const PLACEHOLDER_PREKEY = btoa("placeholder-signed-prekey-public");
    const PLACEHOLDER_SIGNATURE = btoa("placeholder-signed-prekey-signature");
    const PLACEHOLDER_PREKEY_ID = 1;

    // Generate placeholder one-time prekeys
    const placeholderOneTimePrekeys = Array.from({ length: 10 }, (_, i) => ({
      prekey_id: i + 1,
      public_key: btoa(`placeholder-otpk-${i + 1}`),
    }));

    // Call the register-device Edge Function
    const { data, error } = await supabase.functions.invoke("register-device", {
      body: {
        device_type: "web",
        platform: detectPlatform(),
        signed_prekey_public: PLACEHOLDER_PREKEY,
        signed_prekey_signature: PLACEHOLDER_SIGNATURE,
        signed_prekey_id: PLACEHOLDER_PREKEY_ID,
        one_time_prekeys: placeholderOneTimePrekeys,
      },
    });

    if (error) {
      console.error("Device registration error:", error);
      return { success: false, error: error.message };
    }

    // Mark device as registered locally
    localStorage.setItem(DEVICE_REGISTERED_KEY, "true");
    localStorage.setItem(DEVICE_ID_KEY, data.device_id);

    return { success: true, deviceId: data.device_id };
  } catch (err) {
    console.error("Device registration failed:", err);
    return {
      success: false,
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}
