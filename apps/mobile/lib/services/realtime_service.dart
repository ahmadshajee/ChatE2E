// ============================================================
//  Realtime Service
//  Subscribes to Supabase Realtime for:
//  - New incoming envelopes (messages)
//  - Delivery events (status updates for sent messages)
// ============================================================

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import 'message_service.dart';

class RealtimeService {
  final SupabaseClient _client = Supabase.instance.client;
  final MessageService _messageService;
  final AppDatabase _db;
  final String _myDeviceId;

  RealtimeChannel? _envelopeChannel;
  RealtimeChannel? _receiptChannel;

  // Stream controller for notifying UI of new messages
  final _newMessageController = StreamController<String>.broadcast(); // emits conversation_id
  Stream<String> get onNewMessage => _newMessageController.stream;

  RealtimeService(this._messageService, this._db, this._myDeviceId);

  /// Start listening for incoming envelopes and delivery events.
  void subscribe() {
    _subscribeToEnvelopes();
    _subscribeToDeliveryEvents();
  }

  /// Subscribe to new envelopes targeting this device.
  void _subscribeToEnvelopes() {
    _envelopeChannel = _client
        .channel('device_envelopes_$_myDeviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'device_envelopes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_device_id',
            value: _myDeviceId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              await _messageService.processEnvelope(newRecord, _myDeviceId);
              final conversationId = newRecord['conversation_id'] as String?;
              if (conversationId != null) {
                _newMessageController.add(conversationId);
              }
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to delivery events for sent messages.
  void _subscribeToDeliveryEvents() {
    _receiptChannel = _client
        .channel('delivery_events_$_myDeviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'delivery_events',
          callback: (payload) async {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              final envelopeId = newRecord['envelope_id'] as String?;
              final eventType = newRecord['event_type'] as String?;
              if (envelopeId != null && eventType != null) {
                await _handleDeliveryEvent(envelopeId, eventType);
              }
            }
          },
        )
        .subscribe();
  }

  /// Handle a delivery event (update local message status).
  Future<void> _handleDeliveryEvent(String envelopeId, String eventType) async {
    try {
      // Find the local message by envelope ID and update its status
      final conversations = await _db.getConversations();
      for (final conv in conversations) {
        final messages = await _db.getMessages(conv.id);
        for (final msg in messages) {
          if (msg.envelopeId == envelopeId && msg.isMine) {
            String newStatus;
            switch (eventType) {
              case 'delivered':
                newStatus = 'delivered';
                break;
              case 'read':
                newStatus = 'read';
                break;
              default:
                return;
            }
            await _db.updateMessageStatus(msg.id, newStatus);
            _newMessageController.add(conv.id);
            return;
          }
        }
      }
    } catch (_) {}
  }

  /// Unsubscribe from all channels.
  void dispose() {
    _envelopeChannel?.unsubscribe();
    _receiptChannel?.unsubscribe();
    _newMessageController.close();
  }
}
