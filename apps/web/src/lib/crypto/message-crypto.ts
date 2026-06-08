// ============================================================
//  Web Crypto — Message Encryption/Decryption
//  AES-256-GCM using Web Crypto API.
//  Format: base64(nonce || ciphertext || tag)
// ============================================================

function toBase64(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)));
}

function fromBase64(b64: string): ArrayBuffer {
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes.buffer as ArrayBuffer;
}

/**
 * Encrypt plaintext with AES-256-GCM.
 */
export async function encrypt(
  plaintext: string,
  sharedSecretB64: string
): Promise<string> {
  const keyBuffer = fromBase64(sharedSecretB64);
  const key = await crypto.subtle.importKey(
    "raw",
    keyBuffer,
    { name: "AES-GCM" },
    false,
    ["encrypt"]
  );

  const nonce = crypto.getRandomValues(new Uint8Array(12));
  const plaintextBytes = new TextEncoder().encode(plaintext);

  const encrypted = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: nonce },
    key,
    plaintextBytes
  );

  const encryptedArray = new Uint8Array(encrypted);
  const combined = new Uint8Array(nonce.length + encryptedArray.length);
  combined.set(nonce, 0);
  combined.set(encryptedArray, nonce.length);

  return toBase64(combined.buffer as ArrayBuffer);
}

/**
 * Decrypt AES-256-GCM ciphertext.
 */
export async function decrypt(
  ciphertextB64: string,
  sharedSecretB64: string
): Promise<string> {
  const keyBuffer = fromBase64(sharedSecretB64);
  const key = await crypto.subtle.importKey(
    "raw",
    keyBuffer,
    { name: "AES-GCM" },
    false,
    ["decrypt"]
  );

  const combined = new Uint8Array(fromBase64(ciphertextB64));
  const nonce = combined.slice(0, 12);
  const ciphertext = combined.slice(12);

  const decrypted = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: nonce },
    key,
    ciphertext.buffer as ArrayBuffer
  );

  return new TextDecoder().decode(decrypted);
}

/**
 * Generate a random AES-256 key.
 */
export async function generateRandomKey(): Promise<string> {
  const key = await crypto.subtle.generateKey(
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"]
  );
  const raw = await crypto.subtle.exportKey("raw", key);
  return toBase64(raw);
}
