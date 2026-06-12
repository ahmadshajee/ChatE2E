// ============================================================
//  Session Manager
//  Simplified X3DH key agreement for establishing shared secrets
//  between device pairs. Full Double Ratchet deferred to Part 3.
//
//  Flow:
//  Initiator → fetch peer prekey bundle → DH → derive shared key
//  Responder → receive prekey_message → DH → derive same key
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import 'key_manager.dart';

/// Prekey bundle fetched from server for a peer device.
class PrekeyBundle {
  final String deviceId;
  final String identityPublicKey;  // Base64
  final String signedPrekeyPublic; // Base64
  final String signedPrekeySignature; // Base64
  final int signedPrekeyId;
  final String? oneTimePrekeyPublic; // Base64 (nullable — may be exhausted)
  final int? oneTimePrekeyId;

  PrekeyBundle({
    required this.deviceId,
    required this.identityPublicKey,
    required this.signedPrekeyPublic,
    required this.signedPrekeySignature,
    required this.signedPrekeyId,
    this.oneTimePrekeyPublic,
    this.oneTimePrekeyId,
  });
}

/// Header sent with a prekey_message so the recipient can establish the session.
class PrekeyMessageHeader {
  final String ephemeralPublicKey; // Base64
  final String senderIdentityKey;  // Base64
  final int? usedOneTimePrekeyId;

  PrekeyMessageHeader({
    required this.ephemeralPublicKey,
    required this.senderIdentityKey,
    this.usedOneTimePrekeyId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ephemeral_public_key': ephemeralPublicKey,
    'sender_identity_key': senderIdentityKey,
    'used_one_time_prekey_id': usedOneTimePrekeyId,
  };

  factory PrekeyMessageHeader.fromJson(Map<String, dynamic> json) {
    return PrekeyMessageHeader(
      ephemeralPublicKey: json['ephemeral_public_key'] as String,
      senderIdentityKey: json['sender_identity_key'] as String,
      usedOneTimePrekeyId: json['used_one_time_prekey_id'] as int?,
    );
  }
}

class SessionManager {
  final AppDatabase _db;
  final KeyManager _keyManager;
  final _x25519 = X25519();
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  SessionManager(this._db, this._keyManager);

  /// Check if we have an established session with a peer device.
  Future<bool> hasSession(String myDeviceId, String peerDeviceId) async {
    final session = await _db.getSessionKey(myDeviceId, peerDeviceId);
    return session != null;
  }

  /// Get the shared secret for an established session.
  Future<String?> getSessionKey(String myDeviceId, String peerDeviceId) async {
    final session = await _db.getSessionKey(myDeviceId, peerDeviceId);
    return session?.sharedSecret;
  }

  // ── Initiator Side (Sender) ───────────────────────────────

  /// Establish a new session with a peer device using their prekey bundle.
  /// Returns the shared secret (Base64) and a PrekeyMessageHeader to include
  /// in the first message.
  Future<({String sharedSecret, PrekeyMessageHeader header})>
      initiateSession(String myDeviceId, PrekeyBundle peerBundle) async {
    // 1. Get our identity private key
    final identityPrivBytes = await _keyManager.getIdentityPrivateKeyBytes();
    if (identityPrivBytes == null) {
      throw StateError('Identity key not found');
    }
    final identityPubB64 = await _keyManager.getIdentityPublicKey();

    // 2. Generate ephemeral keypair
    final ephemeralKp = await _x25519.newKeyPair();
    final ephemeralPrivBytes = await ephemeralKp.extractPrivateKeyBytes();
    final ephemeralPubKey = await ephemeralKp.extractPublicKey();
    final ephemeralPubB64 = base64Encode(Uint8List.fromList(ephemeralPubKey.bytes));

    // 3. Decode peer's keys
    final peerSignedPrekeyPub = SimplePublicKey(
      base64Decode(peerBundle.signedPrekeyPublic),
      type: KeyPairType.x25519,
    );
    final peerIdentityPub = SimplePublicKey(
      base64Decode(peerBundle.identityPublicKey),
      type: KeyPairType.x25519,
    );

    // 4. Perform DH computations
    // DH1: identity_private × peer_signed_prekey
    final identityKp = await _x25519.newKeyPairFromSeed(identityPrivBytes.sublist(0, 32));
    final dh1 = await _x25519.sharedSecretKey(
      keyPair: identityKp,
      remotePublicKey: peerSignedPrekeyPub,
    );

    // DH2: ephemeral_private × peer_identity_key
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: ephemeralKp,
      remotePublicKey: peerIdentityPub,
    );

    // DH3: ephemeral_private × peer_signed_prekey
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: ephemeralKp,
      remotePublicKey: peerSignedPrekeyPub,
    );

    // Combine DH outputs
    final dh1Bytes = await dh1.extractBytes();
    final dh2Bytes = await dh2.extractBytes();
    final dh3Bytes = await dh3.extractBytes();
    var combinedDH = Uint8List.fromList([...dh1Bytes, ...dh2Bytes, ...dh3Bytes]);

    // DH4: ephemeral × one_time_prekey (if available)
    int? usedOtpId;
    if (peerBundle.oneTimePrekeyPublic != null) {
      final otpPub = SimplePublicKey(
        base64Decode(peerBundle.oneTimePrekeyPublic!),
        type: KeyPairType.x25519,
      );
      final dh4 = await _x25519.sharedSecretKey(
        keyPair: ephemeralKp,
        remotePublicKey: otpPub,
      );
      final dh4Bytes = await dh4.extractBytes();
      combinedDH = Uint8List.fromList([...combinedDH, ...dh4Bytes]);
      usedOtpId = peerBundle.oneTimePrekeyId;
    }

    // 5. Derive shared secret via HKDF
    final sharedSecretKey = await _hkdf.deriveKey(
      secretKey: SecretKey(combinedDH),
      nonce: utf8.encode('ChatizyX3DH'),
    );
    final sharedSecretBytes = await sharedSecretKey.extractBytes();
    final sharedSecretB64 = base64Encode(Uint8List.fromList(sharedSecretBytes));

    // 6. Store session key locally
    await _db.storeSessionKey(SessionKeysCompanion(
      id: Value('$myDeviceId:${peerBundle.deviceId}'),
      peerDeviceId: Value(peerBundle.deviceId),
      sharedSecret: Value(sharedSecretB64),
      establishedAt: Value(DateTime.now()),
      peerIdentityKey: Value(peerBundle.identityPublicKey),
    ));

    // 7. Return header for the prekey_message
    final header = PrekeyMessageHeader(
      ephemeralPublicKey: ephemeralPubB64,
      senderIdentityKey: identityPubB64!,
      usedOneTimePrekeyId: usedOtpId,
    );

    return (sharedSecret: sharedSecretB64, header: header);
  }

  // ── Responder Side (Recipient) ────────────────────────────

  /// Process a received prekey_message header to establish the session.
  /// Returns the shared secret (Base64).
  Future<String> respondToSession(
    String myDeviceId,
    String senderDeviceId,
    PrekeyMessageHeader header,
  ) async {
    // 1. Get our keys
    final signedPrekeyPrivBytes = await _keyManager.getSignedPrekeyPrivateBytes();
    final identityPrivBytes = await _keyManager.getIdentityPrivateKeyBytes();
    if (signedPrekeyPrivBytes == null || identityPrivBytes == null) {
      throw StateError('Device keys not found');
    }

    // 2. Decode sender's keys
    final senderIdentityPub = SimplePublicKey(
      base64Decode(header.senderIdentityKey),
      type: KeyPairType.x25519,
    );
    final ephemeralPub = SimplePublicKey(
      base64Decode(header.ephemeralPublicKey),
      type: KeyPairType.x25519,
    );

    // 3. Perform DH computations (mirroring initiator)
    final signedPrekeyKp = await _x25519.newKeyPairFromSeed(signedPrekeyPrivBytes.sublist(0, 32));
    final identityKp = await _x25519.newKeyPairFromSeed(identityPrivBytes.sublist(0, 32));

    // DH1: signed_prekey_private × sender_identity_key
    final dh1 = await _x25519.sharedSecretKey(
      keyPair: signedPrekeyKp,
      remotePublicKey: senderIdentityPub,
    );

    // DH2: identity_private × sender_ephemeral_key
    final dh2 = await _x25519.sharedSecretKey(
      keyPair: identityKp,
      remotePublicKey: ephemeralPub,
    );

    // DH3: signed_prekey_private × sender_ephemeral_key
    final dh3 = await _x25519.sharedSecretKey(
      keyPair: signedPrekeyKp,
      remotePublicKey: ephemeralPub,
    );

    final dh1Bytes = await dh1.extractBytes();
    final dh2Bytes = await dh2.extractBytes();
    final dh3Bytes = await dh3.extractBytes();
    var combinedDH = Uint8List.fromList([...dh1Bytes, ...dh2Bytes, ...dh3Bytes]);

    // DH4: one_time_prekey × sender_ephemeral (if used)
    if (header.usedOneTimePrekeyId != null) {
      final otpPrivBytes = await _keyManager.getOneTimePrekeyPrivateBytes(header.usedOneTimePrekeyId!);
      if (otpPrivBytes != null) {
        final otpKp = await _x25519.newKeyPairFromSeed(otpPrivBytes.sublist(0, 32));
        final dh4 = await _x25519.sharedSecretKey(
          keyPair: otpKp,
          remotePublicKey: ephemeralPub,
        );
        final dh4Bytes = await dh4.extractBytes();
        combinedDH = Uint8List.fromList([...combinedDH, ...dh4Bytes]);
      }
    }

    // 4. Derive shared secret via HKDF (same as initiator)
    final sharedSecretKey = await _hkdf.deriveKey(
      secretKey: SecretKey(combinedDH),
      nonce: utf8.encode('ChatizyX3DH'),
    );
    final sharedSecretBytes = await sharedSecretKey.extractBytes();
    final sharedSecretB64 = base64Encode(Uint8List.fromList(sharedSecretBytes));

    // 5. Store session key locally
    await _db.storeSessionKey(SessionKeysCompanion(
      id: Value('$myDeviceId:$senderDeviceId'),
      peerDeviceId: Value(senderDeviceId),
      sharedSecret: Value(sharedSecretB64),
      establishedAt: Value(DateTime.now()),
      peerIdentityKey: Value(header.senderIdentityKey),
    ));

    return sharedSecretB64;
  }
}
