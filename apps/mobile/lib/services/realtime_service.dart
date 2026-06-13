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

  bool _isDisposed = false;
  Timer? _envelopeReconnectTimer;
  Timer? _receiptReconnectTimer;
  Timer? _heartbeatTimer;

  // Stream controller for notifying UI of new messages
  final _newMessageController = StreamController<String>.broadcast(); // emits conversation_id
  Stream<String> get onNewMessage => _newMessageController.stream;

  RealtimeService(this._messageService, this._db, this._myDeviceId);

  /// Start listening for incoming envelopes and delivery events.
  void subscribe() {
    _isDisposed = false;
    _subscribeToEnvelopes();
    _subscribeToDeliveryEvents();
    _startHeartbeat();
  }

  /// Subscribe to new envelopes targeting this device.
  void _subscribeToEnvelopes() {
    _envelopeReconnectTimer?.cancel();
    if (_isDisposed) return;

    if (_envelopeChannel != null) {
      _client.realtime.removeChannel(_envelopeChannel!);
    }

    print('Subscribing to envelope channel for $_myDeviceId...');
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
        );

    _envelopeChannel!.subscribe((status, [error]) {
      print('Envelope channel status for $_myDeviceId: $status');
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('Envelope channel subscribed successfully. Fetching catch-up envelopes...');
        _messageService.catchUp(_myDeviceId);
      } else if (status == RealtimeSubscribeStatus.channelError || 
                 status == RealtimeSubscribeStatus.closed ||
                 status == RealtimeSubscribeStatus.timedOut) {
        if (error != null) {
          print('Envelope channel error/disconnect: $error');
        }
        _scheduleEnvelopeReconnect();
      }
    });
  }

  void _scheduleEnvelopeReconnect() {
    _envelopeReconnectTimer?.cancel();
    if (_isDisposed) return;
    _envelopeReconnectTimer = Timer(const Duration(seconds: 5), () {
      print('Retrying envelope channel subscription for $_myDeviceId...');
      _subscribeToEnvelopes();
    });
  }

  /// Subscribe to delivery events for sent messages.
  void _subscribeToDeliveryEvents() {
    _receiptReconnectTimer?.cancel();
    if (_isDisposed) return;

    if (_receiptChannel != null) {
      _client.realtime.removeChannel(_receiptChannel!);
    }

    print('Subscribing to delivery events channel for $_myDeviceId...');
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
        );

    _receiptChannel!.subscribe((status, [error]) {
      print('Receipt channel status for $_myDeviceId: $status');
      if (status == RealtimeSubscribeStatus.channelError || 
          status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.timedOut) {
        if (error != null) {
          print('Receipt channel error/disconnect: $error');
        }
        _scheduleReceiptReconnect();
      }
    });
  }

  void _scheduleReceiptReconnect() {
    _receiptReconnectTimer?.cancel();
    if (_isDisposed) return;
    _receiptReconnectTimer = Timer(const Duration(seconds: 5), () {
      print('Retrying receipt channel subscription for $_myDeviceId...');
      _subscribeToDeliveryEvents();
    });
  }

  /// Force reconnection of socket and resubscribe.
  void reconnect() {
    if (_isDisposed) return;
    print('RealtimeService: Reconnecting underlying socket and channels...');
    try {
      // ignore: invalid_use_of_internal_member
      _client.realtime.connect();
    } catch (e) {
      print('RealtimeService: socket connect error: $e');
    }
    _subscribeToEnvelopes();
    _subscribeToDeliveryEvents();
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

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (_isDisposed) return;
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isDisposed) return;
      try {
        final isConnected = _client.realtime.isConnected;
        print('RealtimeService: Heartbeat check. Connected: $isConnected');
        if (!isConnected) {
          print('RealtimeService: Socket disconnected. Reconnecting...');
          reconnect();
        }
      } catch (e) {
        print('RealtimeService: Heartbeat error: $e');
      }
    });
  }

  /// Unsubscribe from all channels.
  void dispose() {
    _isDisposed = true;
    _envelopeReconnectTimer?.cancel();
    _receiptReconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    if (_envelopeChannel != null) {
      _client.realtime.removeChannel(_envelopeChannel!);
      _envelopeChannel = null;
    }
    if (_receiptChannel != null) {
      _client.realtime.removeChannel(_receiptChannel!);
      _receiptChannel = null;
    }
    _newMessageController.close();
  }
}
