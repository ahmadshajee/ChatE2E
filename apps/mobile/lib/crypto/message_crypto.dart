// ============================================================
//  Message Crypto
//  AES-256-GCM encryption/decryption for message payloads.
//  Format: base64(nonce || ciphertext || tag)
// ============================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class MessageCrypto {
  static final _aesGcm = AesGcm.with256bits();

  /// Encrypt plaintext with a shared secret (Base64 key).
  /// Returns a single Base64 string: nonce || ciphertext || tag.
  static Future<String> encrypt(String plaintext, String sharedSecretB64) async {
    final keyBytes = base64Decode(sharedSecretB64);
    final secretKey = SecretKey(keyBytes);
    final plaintextBytes = utf8.encode(plaintext);

    final secretBox = await _aesGcm.encrypt(
      plaintextBytes,
      secretKey: secretKey,
    );

    // Combine: nonce (12 bytes) + ciphertext + mac (16 bytes)
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// Decrypt a Base64 ciphertext string with a shared secret (Base64 key).
  /// Input format: base64(nonce || ciphertext || tag).
  static Future<String> decrypt(String ciphertextB64, String sharedSecretB64) async {
    final keyBytes = base64Decode(sharedSecretB64);
    final secretKey = SecretKey(keyBytes);
    final combined = base64Decode(ciphertextB64);

    // Extract nonce (12 bytes), ciphertext, and mac (16 bytes)
    final nonce = combined.sublist(0, 12);
    final mac = Mac(combined.sublist(combined.length - 16));
    final cipherText = combined.sublist(12, combined.length - 16);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final decrypted = await _aesGcm.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return utf8.decode(decrypted);
  }

  /// Generate a random AES-256 key, returned as Base64.
  static Future<String> generateRandomKey() async {
    final secretKey = await _aesGcm.newSecretKey();
    final keyBytes = await secretKey.extractBytes();
    return base64Encode(Uint8List.fromList(keyBytes));
  }
}
