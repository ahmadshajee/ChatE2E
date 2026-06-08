// ============================================================
//  Device Service
//  Handles device registration with REAL crypto keys.
//  Registers directly via Supabase client inserts (not Edge Function).
// ============================================================

import 'dart:io' show Platform;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../crypto/key_manager.dart';

class DeviceService {
  static const String _deviceIdKey = 'chatizy_device_id';
  static const String _deviceRegisteredKey = 'chatizy_device_registered';

  final SupabaseClient _client = Supabase.instance.client;
  final AppDatabase _db;
  final KeyManager _keyManager;

  DeviceService(this._db, this._keyManager);

  /// Get or create a persistent device ID.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  /// Check if this device has been registered with the server.
  Future<bool> isDeviceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_deviceRegisteredKey) ?? false;
  }

  /// Detect the current platform.
  String _detectPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'android';
  }

  /// Register this device with the server using REAL crypto keys.
  /// Uses direct Supabase inserts (bypasses undeployed Edge Function).
  Future<Map<String, dynamic>> registerDevice() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      // 1. Generate identity keys (if not already generated)
      if (!await _keyManager.hasIdentityKeys()) {
        await _keyManager.generateIdentityKeys();
      }

      // 2. Generate signed prekey
      final signedPrekey = await _keyManager.generateSignedPrekey();

      // 3. Generate one-time prekeys
      final oneTimePrekeys = await _keyManager.generateOneTimePrekeys(10);

      // 4. Get identity public key
      final identityPubKey = await _keyManager.getIdentityPublicKey();

      // 5. Update user's identity_public_key in users table
      await _client
          .from('users')
          .update({'identity_public_key': identityPubKey})
          .eq('id', user.id);

      // 6. Insert device row directly via Supabase client (RLS allows it)
      final deviceId = await getOrCreateDeviceId();
      
      final deviceResponse = await _client
          .from('devices')
          .insert({
            'id': deviceId,
            'user_id': user.id,
            'device_type': 'mobile',
            'platform': _detectPlatform(),
            'signed_prekey_public': signedPrekey['signed_prekey_public'],
            'signed_prekey_signature': signedPrekey['signed_prekey_signature'],
            'signed_prekey_id': int.parse(signedPrekey['signed_prekey_id']!),
            'is_active': true,
          })
          .select('id')
          .single();

      final registeredDeviceId = deviceResponse['id'] as String;

      // 7. Bulk-insert one-time prekeys
      final prekeyRows = oneTimePrekeys.map((pk) => {
        'device_id': registeredDeviceId,
        'prekey_id': pk['prekey_id'],
        'public_key': pk['public_key'],
        'is_consumed': false,
      }).toList();

      await _client.from('one_time_prekeys').insert(prekeyRows);

      // 8. Initialize sync cursor
      await _client.from('device_sync_cursors').insert({
        'device_id': registeredDeviceId,
        'last_envelope_id': null,
        'last_synced_at': DateTime.now().toIso8601String(),
      });

      // 9. Save registration status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, registeredDeviceId);
      await prefs.setBool(_deviceRegisteredKey, true);

      return {
        'success': true,
        'device_id': registeredDeviceId,
        'prekeys_uploaded': oneTimePrekeys.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
