// ============================================================
//  Chat List Screen
//  Shows all conversations from local storage.
//  FAB to start new chats. Pull-to-refresh syncs from server.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';


import '../database/app_database.dart';
import '../crypto/key_manager.dart';
import '../crypto/session_manager.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/conversation_service.dart';
import '../services/message_service.dart';
import '../services/realtime_service.dart';
import '../widgets/conversation_tile.dart';
import 'new_chat_screen.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  final AppDatabase db;

  const ChatListScreen({super.key, required this.db});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthService _authService = AuthService();
  late final DeviceService _deviceService;
  late final ConversationService _conversationService;
  late final MessageService _messageService;
  late final KeyManager _keyManager;
  late final SessionManager _sessionManager;
  RealtimeService? _realtimeService;

  String _deviceId = '';
  bool _deviceRegistered = false;
  bool _isRegistering = false;
  StreamSubscription? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _keyManager = KeyManager(widget.db);
    _sessionManager = SessionManager(widget.db, _keyManager);
    _deviceService = DeviceService(widget.db, _keyManager);
    _conversationService = ConversationService(widget.db);
    _messageService = MessageService(widget.db, _keyManager, _sessionManager);
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadDeviceInfo();

    // Auto-register device if not yet registered
    if (!_deviceRegistered) {
      await _registerDevice();
    }

    // Sync conversations from server
    await _conversationService.syncConversations();

    // Start realtime subscription
    if (_deviceId.isNotEmpty) {
      _realtimeService = RealtimeService(_messageService, widget.db, _deviceId);
      _realtimeService!.subscribe();
      _realtimeSub = _realtimeService!.onNewMessage.listen((_) {
        // Trigger UI refresh (StreamBuilder handles it, but this ensures sync)
        setState(() {});
      });

      // Catch up any pending messages
      await _messageService.catchUp(_deviceId);
    }
  }

  Future<void> _loadDeviceInfo() async {
    final deviceId = await _deviceService.getOrCreateDeviceId();
    final registered = await _deviceService.isDeviceRegistered();
    if (mounted) {
      setState(() {
        _deviceId = deviceId;
        _deviceRegistered = registered;
      });
    }
  }

  Future<void> _registerDevice() async {
    setState(() => _isRegistering = true);
    try {
      final result = await _deviceService.registerDevice();
      if (result['success'] == true) {
        await _loadDeviceInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device registered with E2E encryption keys'),
              backgroundColor: Color(0xFF00A884),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${result['error']}'),
              backgroundColor: const Color(0xFFEA4335),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration error: $e'),
            backgroundColor: const Color(0xFFEA4335),
          ),
        );
      }
    }
    if (mounted) setState(() => _isRegistering = false);
  }

  Future<void> _refresh() async {
    await _conversationService.syncConversations();
    if (_deviceId.isNotEmpty) {
      await _messageService.catchUp(_deviceId);
    }
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _realtimeService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chatizy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE9EDEF),
              ),
            ),
            Text(
              'End-to-End Encrypted',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8696A0),
              ),
            ),
          ],
        ),
        actions: [
          // Device badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _deviceRegistered
                  ? const Color(0xFF00A884).withValues(alpha: 0.1)
                  : const Color(0xFFFFA726).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _deviceRegistered
                    ? const Color(0xFF00A884).withValues(alpha: 0.2)
                    : const Color(0xFFFFA726).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isRegistering)
                  const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFFFFA726),
                    ),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _deviceRegistered
                          ? const Color(0xFF00A884)
                          : const Color(0xFFFFA726),
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  _isRegistering
                      ? 'Registering...'
                      : _deviceRegistered
                          ? '${_deviceId.substring(0, 8)}...'
                          : 'No Device',
                  style: TextStyle(
                    fontSize: 11,
                    color: _deviceRegistered
                        ? const Color(0xFF00A884)
                        : const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
          ),

          // Sign out
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171), size: 20),
            onPressed: () async {
              _realtimeService?.dispose();
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF00A884),
        backgroundColor: const Color(0xFF1F2C34),
        child: StreamBuilder<List<LocalConversation>>(
          stream: _conversationService.watchConversations(),
          builder: (context, snapshot) {
            final conversations = snapshot.data ?? [];

            if (conversations.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 64,
                            color: const Color(0xFF8696A0).withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFE9EDEF),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to start a new chat',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8696A0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 82),
                child: Divider(
                  height: 0.5,
                  color: const Color(0xFF233138).withValues(alpha: 0.5),
                ),
              ),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return ConversationTile(
                  conversation: conv,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          conversationId: conv.id,
                          peerName: conv.peerDisplayName,
                          db: widget.db,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NewChatScreen(db: widget.db),
            ),
          );
        },
        backgroundColor: const Color(0xFF00A884),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
