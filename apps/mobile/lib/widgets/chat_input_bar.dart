// ============================================================
//  Chat Input Bar Widget
//  Message compose bar with iOS iMessage style.
//  Supports reply context — shows "Reply" placeholder and
//  a slim reply preview strip above the text field.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/sound_service.dart';
import '../database/app_database.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;
  final LocalMessage? replyingTo;
  final VoidCallback? onCancelReply;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    SoundService().playSend();
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final isReplying = widget.replyingTo != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview strip (iMessage style — shows above the text field)
          if (isReplying) _buildReplyStrip(),

          // Main input row
          Padding(
            padding: EdgeInsets.only(
              left: 10,
              right: 10,
              top: isReplying ? 4 : 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Plus Action Button on the Left
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    onTap: () {
                      // Custom plus menu action
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Text field container
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5E5EA),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: isReplying ? 'Reply' : 'iMessage',
                              hintStyle: TextStyle(
                                color: isReplying
                                    ? const Color(0xFFC7C7CC)
                                    : const Color(0xFFC7C7CC),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (text) {
                              SoundService().playClick();
                              setState(() => _hasText = text.trim().isNotEmpty);
                            },
                            onSubmitted: (_) => _handleSend(),
                          ),
                        ),
                        if (!_hasText)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              CupertinoIcons.mic_fill,
                              color: Color(0xFF8E8E93),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Send button (iOS upward arrow in blue circle)
                if (_hasText) ...[
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// iMessage-style reply strip that appears above the input bar
  /// Shows a thin colored bar, sender name, message preview, and X button.
  Widget _buildReplyStrip() {
    final reply = widget.replyingTo!;
    final senderName = reply.isMine ? 'You' : 'Them';

    return Container(
      padding: const EdgeInsets.only(left: 48, right: 12, top: 8, bottom: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Colored accent bar
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            // Reply text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    reply.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Cancel button
            GestureDetector(
              onTap: widget.onCancelReply,
              child: const Icon(
                CupertinoIcons.xmark_circle_fill,
                color: Color(0xFFC7C7CC),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
