// ============================================================
//  Chat Room Screen
//  Displays messages in a conversation and allows sending.
//  Reads from local decrypted storage only.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../crypto/key_manager.dart';
import '../crypto/session_manager.dart';
import '../services/message_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/thread_reply_view.dart';

class ChatRoomScreen extends StatefulWidget {
  final String conversationId;
  final String peerName;
  final AppDatabase db;

  static String? activeConversationId;

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
  LocalMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    ChatRoomScreen.activeConversationId = widget.conversationId;
    _scrollController = ScrollController();
    _initServices();
  }

  Future<void> _initServices() async {
    final keyManager = KeyManager(widget.db);
    final sessionManager = SessionManager(widget.db, keyManager);
    _messageService = MessageService(widget.db, sessionManager);

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
    if (ChatRoomScreen.activeConversationId == widget.conversationId) {
      ChatRoomScreen.activeConversationId = null;
    }
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
      final parentId = _replyingTo?.id;
      if (mounted && _replyingTo != null) {
        setState(() {
          _replyingTo = null;
        });
      }
      await _messageService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        myDeviceId: _myDeviceId!,
        parentMessageId: parentId,
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

  /// Open the iMessage-style thread reply overlay
  void _openThreadReply(LocalMessage message) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, __) {
          return ThreadReplyView(
            parentMessage: message,
            db: widget.db,
            conversationId: widget.conversationId,
            peerName: widget.peerName,
            onSendReply: (content, parentId) async {
              if (_myDeviceId == null) return;
              await _messageService.sendMessage(
                conversationId: widget.conversationId,
                content: content,
                myDeviceId: _myDeviceId!,
                parentMessageId: parentId,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(94),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF2F2F7),
            border: Border(
              bottom: BorderSide(color: Color(0x1A000000), width: 0.5),
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 5,
            bottom: 6,
            left: 12,
            right: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button Pill
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.chevron_left,
                        color: Colors.black,
                        size: 18,
                      ),
                      StreamBuilder<int>(
                        stream: widget.db.watchTotalUnreadCountExcept(widget.conversationId),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          if (count == 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Center Avatar + Info
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8C9EC5),
                    ),
                    child: widget.peerName == 'Saurabh'
                        ? ClipOval(
                            child: Image.asset(
                              'assets/profile_saurabh.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
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
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.peerName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey,
                        size: 10,
                      ),
                    ],
                  ),
                  if (widget.peerName == 'Saurabh')
                    const Text(
                      'Not on Chatizy yet',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),

              // Videocam Button
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.video_camera,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF007AFF)),
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

                      final messageMap = {for (var m in messages) m.id: m};

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length + (widget.peerName == 'Saurabh' ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (widget.peerName == 'Saurabh') {
                            if (index == 0) {
                              return _buildInviteBanner();
                            }
                            final msg = messages[index - 1];
                            final parentMsg = msg.parentMessageId != null ? messageMap[msg.parentMessageId] : null;
                            return MessageBubble(
                              message: msg,
                              parentMessage: parentMsg,
                              onReply: () => _openThreadReply(msg),
                              onDelete: () => _deleteMessage(msg),
                              onForward: () => _forwardMessage(msg),
                              onReaction: (emoji) => _handleReaction(msg, emoji),
                              onParentMessageTap: msg.parentMessageId == null ? null : () {
                                final parentIndex = messages.indexWhere((m) => m.id == msg.parentMessageId);
                                if (parentIndex != -1) {
                                  final targetIndex = parentIndex + 1;
                                  final offset = targetIndex * 75.0;
                                  _scrollController.animateTo(
                                    offset.clamp(0.0, _scrollController.position.maxScrollExtent),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                            );
                          }
                          final msg = messages[index];
                          final parentMsg = msg.parentMessageId != null ? messageMap[msg.parentMessageId] : null;
                          return MessageBubble(
                            message: msg,
                            parentMessage: parentMsg,
                            onReply: () => _openThreadReply(msg),
                            onDelete: () => _deleteMessage(msg),
                            onForward: () => _forwardMessage(msg),
                            onReaction: (emoji) => _handleReaction(msg, emoji),
                            onParentMessageTap: msg.parentMessageId == null ? null : () {
                              final parentIndex = messages.indexWhere((m) => m.id == msg.parentMessageId);
                              if (parentIndex != -1) {
                                final offset = parentIndex * 75.0;
                                _scrollController.animateTo(
                                  offset.clamp(0.0, _scrollController.position.maxScrollExtent),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                // Input bar (with integrated reply preview)
                ChatInputBar(
                  onSend: _handleSend,
                  replyingTo: _replyingTo,
                  onCancelReply: () {
                    setState(() => _replyingTo = null);
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildInviteBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F000000), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.info_circle,
            color: Color(0xFFFF3B30),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Saurabh is not a user yet',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Invite them to Chatizy to start E2E encrypted chats.',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitation sent to Saurabh!'),
                  backgroundColor: Color(0xFF007AFF),
                ),
              );
            },
            child: const Text(
              'Invite',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(LocalMessage message) async {
    await widget.db.deleteMessage(message.id);
  }

  Future<void> _handleReaction(LocalMessage message, String? emoji) async {
    if (_myDeviceId != null) {
      await _messageService.sendReaction(
        conversationId: widget.conversationId,
        messageId: message.id,
        emoji: emoji,
        myDeviceId: _myDeviceId!,
      );
    }
  }

  void _forwardMessage(LocalMessage message) async {
    final conversations = await widget.db.getConversations();
    final otherConversations =
        conversations.where((c) => c.id != widget.conversationId).toList();

    if (otherConversations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No other conversations to forward to'),
            backgroundColor: Color(0xFFFF3B30),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Forward Message To'),
          message: const Text('Select a conversation to forward this message to'),
          actions: otherConversations.map((conv) {
            return CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_myDeviceId != null) {
                  await _messageService.sendMessage(
                    conversationId: conv.id,
                    content: message.content,
                    myDeviceId: _myDeviceId!,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Forwarded to ${conv.peerDisplayName}'),
                        backgroundColor: const Color(0xFF007AFF),
                      ),
                    );
                  }
                }
              },
              child: Text(
                conv.peerDisplayName,
                style: const TextStyle(color: Color(0xFF007AFF)),
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
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
