// ============================================================
//  Chat Input Bar Widget
//  Message compose bar with text field and send button.
// ============================================================

import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSend;

  const ChatInputBar({super.key, required this.onSend});

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

    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        border: Border(
          top: BorderSide(color: Color(0xFF233138), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  hintStyle: TextStyle(color: Color(0xFF8696A0)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (text) {
                  setState(() => _hasText = text.trim().isNotEmpty);
                },
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hasText
                  ? const Color(0xFF00A884)
                  : const Color(0xFF00A884).withValues(alpha: 0.4),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _hasText ? _handleSend : null,
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
