// ============================================================
//  Message Service
//  Handles the send/receive pipeline for encrypted messages.
//  Send: plaintext → encrypt → ciphertext envelope → server
//  Receive: server → fetch/realtime → decrypt → local plaintext
//  Server NEVER sees plaintext.
// ============================================================

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../crypto/key_manager.dart';
import '../crypto/session_manager.dart';
import '../crypto/message_crypto.dart';

import 'package:flutter/widgets.dart';
import '../screens/chat_room_screen.dart';
import 'notification_service.dart';
import 'sound_service.dart';

class MessageService {
  final SupabaseClient _client = Supabase.instance.client;
  final AppDatabase _db;
  final KeyManager _keyManager;
  final SessionManager _sessionManager;

  MessageService(this._db, this._keyManager, this._sessionManager);

  String? get _currentUserId => _client.auth.currentUser?.id;

  // ── Send Flow ─────────────────────────────────────────────

  /// Send a message in a conversation.
  /// 1. Store plaintext locally
  /// 2. Find recipient devices
  /// 3. Encrypt per device
  /// 4. Send ciphertext envelopes to server
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    required String myDeviceId,
    String? parentMessageId,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    final messageId = const Uuid().v4();
    final now = DateTime.now();

    // 1. Store plaintext locally with 'pending' status
    await _db.insertMessage(LocalMessagesCompanion(
      id: Value(messageId),
      conversationId: Value(conversationId),
      senderId: Value(userId),
      content: Value(content),
      sentAt: Value(now),
      status: const Value('pending'),
      isMine: const Value(true),
      parentMessageId: Value(parentMessageId),
    ));

    // Update conversation last message
    await _db.updateConversationLastMessage(
      conversationId,
      content,
      now,
    );

    try {
      // 2. Find the recipient's active devices
      final peerDevices = await _findPeerDevices(conversationId, userId);
      if (peerDevices.isEmpty) {
        await _db.updateMessageStatus(messageId, 'failed');
        return;
      }

      // 3. For each peer device, encrypt and send
      for (final device in peerDevices) {
        final targetDeviceId = device['id'] as String;
        final targetUserId = device['user_id'] as String;

        // Check for existing session
        String? sharedSecret = await _sessionManager.getSessionKey(myDeviceId, targetDeviceId);
        String envelopeType = 'message';
        Map<String, dynamic>? headerJson;

        if (sharedSecret == null) {
          // No session — initiate X3DH
          final bundle = await _fetchPrekeyBundle(targetDeviceId, targetUserId);
          if (bundle == null) {
            continue; // Skip this device if no prekey bundle available
          }
          final result = await _sessionManager.initiateSession(myDeviceId, bundle);
          sharedSecret = result.sharedSecret;
          headerJson = result.header.toJson();
          envelopeType = 'prekey_message';

          // Mark the used one-time prekey as consumed on server
          if (bundle.oneTimePrekeyId != null) {
            await _consumeOneTimePrekey(targetDeviceId, bundle.oneTimePrekeyId!);
          }
        }

        // 4. Encrypt the message
        final ciphertext = await MessageCrypto.encrypt(content, sharedSecret);

        // Build the envelope payload (ciphertext + optional header)
        final envelopePayload = jsonEncode({
          'ciphertext': ciphertext,
          if (headerJson != null) 'header': headerJson,
          'client_message_id': messageId,
          if (parentMessageId != null) 'parent_message_id': parentMessageId,
        });

        // 5. Insert envelope on server
        final envelopeResponse = await _client
            .from('device_envelopes')
            .insert({
              'conversation_id': conversationId,
              'sender_device_id': myDeviceId,
              'target_device_id': targetDeviceId,
              'client_message_id': messageId,
              'ciphertext': base64Encode(utf8.encode(envelopePayload)),
              'envelope_type': envelopeType,
              'status': 'pending',
            })
            .select('id')
            .single();

        // Store envelope ID on the local message
        await _db.updateMessageEnvelopeId(
          messageId,
          envelopeResponse['id'] as String,
        );
      }

      // 6. Update local message status
      await _db.updateMessageStatus(messageId, 'sent');
    } catch (e) {
      print('Send error: $e');
      await _db.updateMessageStatus(messageId, 'failed');
      rethrow;
    }
  }

  // ── Receive Flow ──────────────────────────────────────────

  /// Process a received envelope (from Realtime or catch-up).
  /// Decrypts the ciphertext and stores plaintext locally.
  Future<void> processEnvelope(Map<String, dynamic> envelope, String myDeviceId) async {
    try {
      final envelopeId = envelope['id'] as String;
      final conversationId = envelope['conversation_id'] as String;
      final senderDeviceId = envelope['sender_device_id'] as String;
      final envelopeType = envelope['envelope_type'] as String;
      final rawCiphertext = envelope['ciphertext'] as String;
      final clientMessageId = envelope['client_message_id'] as String;

      // Check if we already have this message locally (dedup)
      final existingMessages = await _db.getMessages(conversationId);
      if (existingMessages.any((m) => m.id == clientMessageId)) {
        // Already processed — just ack
        await _ackEnvelope(envelopeId);
        return;
      }

      // Decode the envelope payload
      final payloadJson = utf8.decode(base64Decode(rawCiphertext));
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final ciphertext = payload['ciphertext'] as String;
      final parentMessageId = payload['parent_message_id'] as String?;

      // Get or establish session key
      String? sharedSecret;

      if (envelopeType == 'prekey_message') {
        // New session — process the header to derive the shared secret
        final headerJson = payload['header'] as Map<String, dynamic>;
        final header = PrekeyMessageHeader.fromJson(headerJson);
        sharedSecret = await _sessionManager.respondToSession(
          myDeviceId,
          senderDeviceId,
          header,
        );
      } else {
        // Existing session
        sharedSecret = await _sessionManager.getSessionKey(myDeviceId, senderDeviceId);
      }

      if (sharedSecret == null) {
        print('No session key for device $senderDeviceId — cannot decrypt');
        return;
      }

      // Decrypt the message
      final plaintext = await MessageCrypto.decrypt(ciphertext, sharedSecret);

      // Find the sender's user ID from the device
      final senderUserId = await _getDeviceOwner(senderDeviceId);

      // Store plaintext locally
      final now = DateTime.now();
      await _db.insertMessage(LocalMessagesCompanion(
        id: Value(clientMessageId),
        conversationId: Value(conversationId),
        senderId: Value(senderUserId ?? 'unknown'),
        content: Value(plaintext),
        sentAt: Value(now),
        status: const Value('delivered'),
        isMine: const Value(false),
        envelopeId: Value(envelopeId),
        parentMessageId: Value(parentMessageId),
      ));

      // Update conversation
      await _db.updateConversationLastMessage(
        conversationId,
        plaintext,
        now,
        incrementUnread: true,
      );
      // Trigger local notification if app is in background or this conversation is not active
      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      final isAppInBackground = lifecycleState != null && 
          lifecycleState != AppLifecycleState.resumed;
      final isCurrentChatActive = ChatRoomScreen.activeConversationId == conversationId;

      if (isAppInBackground || !isCurrentChatActive) {
        final conversation = await _db.getConversation(conversationId);
        final senderName = conversation?.peerDisplayName ?? 'New Message';
        final notifId = clientMessageId.hashCode;

        await NotificationService().showNotification(
          id: notifId,
          title: senderName,
          body: plaintext,
          payload: conversationId,
        );
      }
      
      // Play receive sound if the app is in the foreground
      if (!isAppInBackground) {
        SoundService().playReceive();
      }

      // Ack the envelope on server
      await _ackEnvelope(envelopeId);
    } catch (e) {
      print('Process envelope error: $e');
    }
  }

  /// Catch-up: fetch all pending envelopes for this device and process them.
  Future<void> catchUp(String myDeviceId) async {
    try {
      final pendingEnvelopes = await _client
          .from('device_envelopes')
          .select()
          .eq('target_device_id', myDeviceId)
          .eq('status', 'pending')
          .order('created_at');

      for (final envelope in (pendingEnvelopes as List)) {
        await processEnvelope(envelope as Map<String, dynamic>, myDeviceId);
      }
    } catch (e) {
      print('Catch-up error: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  /// Find all active devices of the peer user(s) in a conversation.
  Future<List<Map<String, dynamic>>> _findPeerDevices(
      String conversationId, String currentUserId) async {
    // Get peer members
    final members = await _client
        .from('conversation_members')
        .select('user_id')
        .eq('conversation_id', conversationId)
        .neq('user_id', currentUserId);

    final peerUserIds = (members as List)
        .map((m) => m['user_id'] as String)
        .toList();

    if (peerUserIds.isEmpty) return [];

    // Get their active devices
    final devices = await _client
        .from('devices')
        .select('id, user_id')
        .inFilter('user_id', peerUserIds)
        .eq('is_active', true);

    return (devices as List)
        .map((d) => d as Map<String, dynamic>)
        .toList();
  }

  /// Fetch a prekey bundle for a target device.
  Future<PrekeyBundle?> _fetchPrekeyBundle(
      String deviceId, String userId) async {
    try {
      // Get device info
      final device = await _client
          .from('devices')
          .select('id, signed_prekey_public, signed_prekey_signature, signed_prekey_id')
          .eq('id', deviceId)
          .single();

      // Get user's identity key
      final user = await _client
          .from('users')
          .select('identity_public_key')
          .eq('id', userId)
          .single();

      final identityPubKey = user['identity_public_key'] as String?;
      if (identityPubKey == null) return null;

      // Get an unconsumed one-time prekey
      final otpResponse = await _client
          .from('one_time_prekeys')
          .select('id, prekey_id, public_key')
          .eq('device_id', deviceId)
          .eq('is_consumed', false)
          .limit(1)
          .maybeSingle();

      return PrekeyBundle(
        deviceId: deviceId,
        identityPublicKey: identityPubKey,
        signedPrekeyPublic: device['signed_prekey_public'] as String,
        signedPrekeySignature: device['signed_prekey_signature'] as String,
        signedPrekeyId: device['signed_prekey_id'] as int,
        oneTimePrekeyPublic: otpResponse?['public_key'] as String?,
        oneTimePrekeyId: otpResponse?['prekey_id'] as int?,
      );
    } catch (e) {
      print('Fetch prekey bundle error: $e');
      return null;
    }
  }

  /// Mark a one-time prekey as consumed on the server.
  Future<void> _consumeOneTimePrekey(String deviceId, int prekeyId) async {
    try {
      await _client
          .from('one_time_prekeys')
          .update({'is_consumed': true})
          .eq('device_id', deviceId)
          .eq('prekey_id', prekeyId);
    } catch (_) {}
  }

  /// Acknowledge an envelope (mark as delivered).
  Future<void> _ackEnvelope(String envelopeId) async {
    try {
      await _client
          .from('device_envelopes')
          .update({'status': 'delivered'})
          .eq('id', envelopeId);

      // Also insert a delivery event
      final userId = _currentUserId;
      if (userId != null) {
        // Get device ID for the delivery event
        final deviceResponse = await _client
            .from('devices')
            .select('id')
            .eq('user_id', userId)
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();

        if (deviceResponse != null) {
          await _client.from('delivery_events').insert({
            'envelope_id': envelopeId,
            'device_id': deviceResponse['id'],
            'event_type': 'delivered',
          });
        }
      }
    } catch (_) {}
  }

  /// Get the user_id that owns a device.
  Future<String?> _getDeviceOwner(String deviceId) async {
    try {
      final device = await _client
          .from('devices')
          .select('user_id')
          .eq('id', deviceId)
          .maybeSingle();
      return device?['user_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Watch messages for a conversation.
  Stream<List<LocalMessage>> watchMessages(String conversationId) {
    return _db.watchMessages(conversationId);
  }

  /// Get messages for a conversation.
  Future<List<LocalMessage>> getMessages(String conversationId) {
    return _db.getMessages(conversationId);
  }
}
