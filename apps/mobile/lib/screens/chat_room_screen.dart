// ============================================================
//  Chat Room Screen
//  Displays messages in a conversation and allows sending.
//  Reads from local decrypted storage only.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../crypto/key_manager.dart';
import '../crypto/session_manager.dart';
import '../services/message_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String peerName;
  final AppDatabase db;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.db,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final MessageService _messageService;
  late final ScrollController _scrollController;
  String? _myDeviceId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _initServices();
  }

  Future<void> _initServices() async {
    final keyManager = KeyManager(widget.db);
    final sessionManager = SessionManager(widget.db, keyManager);
    _messageService = MessageService(widget.db, keyManager, sessionManager);

    final prefs = await SharedPreferences.getInstance();
    _myDeviceId = prefs.getString('chatizy_device_id');

    // Mark conversation as read
    await widget.db.resetUnreadCount(widget.conversationId);

    // Catch up any pending messages for this conversation
    if (_myDeviceId != null) {
      await _messageService.catchUp(_myDeviceId!);
    }

    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSend(String content) async {
    if (_myDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device not registered. Please restart the app.'),
          backgroundColor: Color(0xFFEA4335),
        ),
      );
      return;
    }

    try {
      await _messageService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        myDeviceId: _myDeviceId!,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: const Color(0xFFEA4335),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 0,
        leadingWidth: 30,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9EDEF)),
          onPressed: () => Navigator.of(context).pop(),
          padding: EdgeInsets.zero,
        ),
        title: Row(
          children: [
            // Peer avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00A884),
                    const Color(0xFF00CF93),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.peerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peerName,
                  style: const TextStyle(
                    color: Color(0xFFE9EDEF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 10,
                      color: const Color(0xFF00A884).withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'End-to-end encrypted',
                      style: TextStyle(
                        color: Color(0xFF8696A0),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00A884)),
            )
          : Column(
              children: [
                // Messages
                Expanded(
                  child: StreamBuilder<List<LocalMessage>>(
                    stream: _messageService.watchMessages(widget.conversationId),
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_outline,
                                size: 48,
                                color: const Color(0xFF00A884).withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Messages are end-to-end encrypted.\nNo one outside of this chat can read them.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF8696A0).withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(message: messages[index]);
                        },
                      );
                    },
                  ),
                ),

                // Input bar
                ChatInputBar(onSend: _handleSend),
              ],
            ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
