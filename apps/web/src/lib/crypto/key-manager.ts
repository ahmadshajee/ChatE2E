// ============================================================
//  Web Crypto — Key Manager
//  Uses Web Crypto API for key generation.
// ============================================================

import { storeDeviceKey, getDeviceKey } from "../db/local-db";

const KEY_NAMES = {
  identityPrivate: "identity_private",
  identityPublic: "identity_public",
  signedPrekeyPrivate: "signed_prekey_private",
  signedPrekeyPublic: "signed_prekey_public",
  signedPrekeySignature: "signed_prekey_signature",
  signedPrekeyId: "signed_prekey_id",
};

function toBase64(buffer: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)));
}

function fromBase64(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

export async function generateIdentityKeys(): Promise<{
  identityPublicKey: string;
}> {
  // Generate X25519 keypair (using ECDH with P-256 as Web Crypto doesn't support X25519 natively)
  // For production, use a library like @noble/curves for real X25519
  const keyPair = await crypto.subtle.generateKey(
    { name: "ECDH", namedCurve: "P-256" },
    true,
    ["deriveKey", "deriveBits"]
  );

  const privKey = await crypto.subtle.exportKey("pkcs8", keyPair.privateKey);
  const pubKey = await crypto.subtle.exportKey("raw", keyPair.publicKey);

  await storeDeviceKey(KEY_NAMES.identityPrivate, toBase64(privKey));
  await storeDeviceKey(KEY_NAMES.identityPublic, toBase64(pubKey));

  return { identityPublicKey: toBase64(pubKey) };
}

export async function generateSignedPrekey(): Promise<{
  signedPrekeyPublic: string;
  signedPrekeySignature: string;
  signedPrekeyId: string;
}> {
  const keyPair = await crypto.subtle.generateKey(
    { name: "ECDH", namedCurve: "P-256" },
    true,
    ["deriveKey", "deriveBits"]
  );

  const pubKey = await crypto.subtle.exportKey("raw", keyPair.publicKey);
  const privKey = await crypto.subtle.exportKey("pkcs8", keyPair.privateKey);

  // Sign the public key with ECDSA (using a generated signing key)
  const signingKey = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    signingKey.privateKey,
    pubKey
  );

  await storeDeviceKey(KEY_NAMES.signedPrekeyPrivate, toBase64(privKey));
  await storeDeviceKey(KEY_NAMES.signedPrekeyPublic, toBase64(pubKey));
  await storeDeviceKey(KEY_NAMES.signedPrekeySignature, toBase64(signature));
  await storeDeviceKey(KEY_NAMES.signedPrekeyId, "1");

  return {
    signedPrekeyPublic: toBase64(pubKey),
    signedPrekeySignature: toBase64(signature),
    signedPrekeyId: "1",
  };
}

export async function generateOneTimePrekeys(
  count: number
): Promise<Array<{ prekey_id: number; public_key: string }>> {
  const prekeys: Array<{ prekey_id: number; public_key: string }> = [];

  for (let i = 0; i < count; i++) {
    const kp = await crypto.subtle.generateKey(
      { name: "ECDH", namedCurve: "P-256" },
      true,
      ["deriveKey", "deriveBits"]
    );
    const pub = await crypto.subtle.exportKey("raw", kp.publicKey);
    const priv = await crypto.subtle.exportKey("pkcs8", kp.privateKey);

    await storeDeviceKey(`otp_prekey_private_${i + 1}`, toBase64(priv));
    prekeys.push({ prekey_id: i + 1, public_key: toBase64(pub) });
  }

  return prekeys;
}

export async function getIdentityPublicKey(): Promise<string | undefined> {
  return getDeviceKey(KEY_NAMES.identityPublic);
}

export async function hasIdentityKeys(): Promise<boolean> {
  const key = await getDeviceKey(KEY_NAMES.identityPublic);
  return key !== undefined;
}
