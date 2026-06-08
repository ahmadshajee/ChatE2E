// ============================================================
//  Key Manager
//  Generates and stores per-device cryptographic keys:
//  - Identity keypair (X25519 for key agreement)
//  - Signed prekey (X25519 + Ed25519 signature)
//  - One-time prekeys (X25519)
//  All private keys stored in local device_key_store only.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import '../database/app_database.dart';

class KeyManager {
  final AppDatabase _db;

  // Algorithms
  final _x25519 = X25519();
  final _ed25519 = Ed25519();
  final _aesGcm = AesGcm.with256bits();

  // Key name constants
  static const String identityPrivateKey = 'identity_private';
  static const String identityPublicKey = 'identity_public';
  static const String signedPrekeyPrivate = 'signed_prekey_private';
  static const String signedPrekeyPublic = 'signed_prekey_public';
  static const String signedPrekeySignature = 'signed_prekey_signature';
  static const String signedPrekeyId = 'signed_prekey_id';
  static const String signingPrivateKey = 'signing_private'; // Ed25519 for signatures
  static const String signingPublicKey = 'signing_public';

  KeyManager(this._db);

  // ── Identity Key Generation ───────────────────────────────

  /// Generate a new identity keypair (X25519) and signing keypair (Ed25519).
  /// Stores both in the local key store. Returns the public keys as Base64.
  Future<Map<String, String>> generateIdentityKeys() async {
    // X25519 identity keypair (for key agreement)
    final identityKp = await _x25519.newKeyPair();
    final identityPrivBytes = await identityKp.extractPrivateKeyBytes();
    final identityPubKey = await identityKp.extractPublicKey();
    final identityPubBytes = identityPubKey.bytes;

    // Ed25519 signing keypair (for prekey signatures)
    final signingKp = await _ed25519.newKeyPair();
    final signingPrivBytes = await signingKp.extractPrivateKeyBytes();
    final signingPubKey = await signingKp.extractPublicKey();
    final signingPubBytes = signingPubKey.bytes;

    // Store all keys
    await _db.storeDeviceKey(identityPrivateKey, base64Encode(Uint8List.fromList(identityPrivBytes)));
    await _db.storeDeviceKey(identityPublicKey, base64Encode(Uint8List.fromList(identityPubBytes)));
    await _db.storeDeviceKey(signingPrivateKey, base64Encode(Uint8List.fromList(signingPrivBytes)));
    await _db.storeDeviceKey(signingPublicKey, base64Encode(Uint8List.fromList(signingPubBytes)));

    return {
      'identity_public_key': base64Encode(Uint8List.fromList(identityPubBytes)),
      'signing_public_key': base64Encode(Uint8List.fromList(signingPubBytes)),
    };
  }

  // ── Signed Prekey Generation ──────────────────────────────

  /// Generate a new signed prekey. Signs the public key with our Ed25519 signing key.
  /// Returns {public_key, signature, prekey_id} as Base64.
  Future<Map<String, String>> generateSignedPrekey({int prekeyId = 1}) async {
    // Generate X25519 keypair for the prekey
    final prekeyKp = await _x25519.newKeyPair();
    final prekeyPrivBytes = await prekeyKp.extractPrivateKeyBytes();
    final prekeyPubKey = await prekeyKp.extractPublicKey();
    final prekeyPubBytes = prekeyPubKey.bytes;

    // Sign the public key with our Ed25519 signing key
    final signingPrivB64 = await _db.getDeviceKey(signingPrivateKey);
    if (signingPrivB64 == null) {
      throw StateError('Signing key not found. Call generateIdentityKeys() first.');
    }

    final signingPrivBytes = base64Decode(signingPrivB64);
    final signingKp = await _ed25519.newKeyPairFromSeed(signingPrivBytes.sublist(0, 32));

    final signature = await _ed25519.sign(
      prekeyPubBytes,
      keyPair: signingKp,
    );

    // Store private prekey
    await _db.storeDeviceKey(signedPrekeyPrivate, base64Encode(Uint8List.fromList(prekeyPrivBytes)));
    await _db.storeDeviceKey(signedPrekeyPublic, base64Encode(Uint8List.fromList(prekeyPubBytes)));
    await _db.storeDeviceKey(signedPrekeySignature, base64Encode(Uint8List.fromList(signature.bytes)));
    await _db.storeDeviceKey(signedPrekeyId, prekeyId.toString());

    return {
      'signed_prekey_public': base64Encode(Uint8List.fromList(prekeyPubBytes)),
      'signed_prekey_signature': base64Encode(Uint8List.fromList(signature.bytes)),
      'signed_prekey_id': prekeyId.toString(),
    };
  }

  // ── One-Time Prekey Generation ────────────────────────────

  /// Generate a batch of one-time prekeys. Returns list of {prekey_id, public_key}.
  /// Private keys are stored locally indexed by prekey_id.
  Future<List<Map<String, dynamic>>> generateOneTimePrekeys(int count, {int startId = 1}) async {
    final prekeys = <Map<String, dynamic>>[];

    for (int i = 0; i < count; i++) {
      final prekeyId = startId + i;
      final kp = await _x25519.newKeyPair();
      final privBytes = await kp.extractPrivateKeyBytes();
      final pubKey = await kp.extractPublicKey();
      final pubBytes = pubKey.bytes;

      // Store private key locally
      await _db.storeDeviceKey(
        'otp_prekey_private_$prekeyId',
        base64Encode(Uint8List.fromList(privBytes)),
      );

      prekeys.add({
        'prekey_id': prekeyId,
        'public_key': base64Encode(Uint8List.fromList(pubBytes)),
      });
    }

    return prekeys;
  }

  // ── Key Retrieval ─────────────────────────────────────────

  /// Get our identity public key as Base64.
  Future<String?> getIdentityPublicKey() => _db.getDeviceKey(identityPublicKey);

  /// Get our identity private key bytes.
  Future<Uint8List?> getIdentityPrivateKeyBytes() async {
    final b64 = await _db.getDeviceKey(identityPrivateKey);
    return b64 != null ? Uint8List.fromList(base64Decode(b64)) : null;
  }

  /// Get our signed prekey private key bytes.
  Future<Uint8List?> getSignedPrekeyPrivateBytes() async {
    final b64 = await _db.getDeviceKey(signedPrekeyPrivate);
    return b64 != null ? Uint8List.fromList(base64Decode(b64)) : null;
  }

  /// Get a one-time prekey private key by ID.
  Future<Uint8List?> getOneTimePrekeyPrivateBytes(int prekeyId) async {
    final b64 = await _db.getDeviceKey('otp_prekey_private_$prekeyId');
    return b64 != null ? Uint8List.fromList(base64Decode(b64)) : null;
  }

  /// Remove a consumed one-time prekey.
  Future<void> consumeOneTimePrekey(int prekeyId) async {
    // We keep the private key locally for now to handle late arrivals.
    // In production, you'd want to mark it consumed and eventually purge.
  }

  /// Check if identity keys have been generated.
  Future<bool> hasIdentityKeys() => _db.hasDeviceKey(identityPublicKey);

  /// Get our signing public key as Base64.
  Future<String?> getSigningPublicKey() => _db.getDeviceKey(signingPublicKey);

  /// Get the AES-GCM algorithm instance.
  AesGcm get aesGcm => _aesGcm;
}
