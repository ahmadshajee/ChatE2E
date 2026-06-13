// ============================================================
//  Chat Input Bar Widget
//  Message compose bar with iOS iMessage style.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/sound_service.dart';

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

    SoundService().playSend();
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Plus Action Button on the Left
          GestureDetector(
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
          const SizedBox(width: 8),

          // Text field container with circular border and mic icon inside
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
                      decoration: const InputDecoration(
                        hintText: 'iMessage',
                        hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
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

          // Send button (iOS upward arrow in blue circle, only visible when there's text)
          if (_hasText) ...[
            const SizedBox(width: 8),
            GestureDetector(
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
          ],
        ],
      ),
    );
  }
}
