// ============================================================
//  Message Bubble Widget
//  Chat bubble with iMessage-style directional styling, colors,
//  tapback reactions, Memoji stickers, and delivery status links.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import '../database/app_database.dart';

class MessageBubble extends StatefulWidget {
  final LocalMessage message;
  final LocalMessage? parentMessage;
  final VoidCallback? onReply;
  final VoidCallback? onParentMessageTap;

  const MessageBubble({
    super.key,
    required this.message,
    this.parentMessage,
    this.onReply,
    this.onParentMessageTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showReplay = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMine = message.isMine;
    final isSticker = message.content == '[sticker:dino]';

    final String? reaction = message.content == 'Hello Test'
        ? '?'
        : (message.content == 'Nahi aaya abhu' ? '😂' : null);

    Widget messageContent;

    if (isSticker) {
      messageContent = _buildSticker('assets/sticker_dino_explode.png');
    } else {
      messageContent = Padding(
        padding: EdgeInsets.only(
          left: isMine ? 60 : 12,
          right: isMine ? 12 : 60,
          top: 4,
          bottom: 4,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF007AFF) // iMessage Blue
                    : const Color(0xFFE5E5EA), // iMessage Light Gray
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 6),
                  bottomRight: Radius.circular(isMine ? 6 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.parentMessage != null)
                    _buildQuoteCard(widget.parentMessage!),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black,
                      fontSize: 16,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (reaction != null)
              Positioned(
                top: -8,
                left: isMine ? -4 : null,
                right: isMine ? null : -4,
                child: _buildReactionBadge(reaction, isMine),
              ),
          ],
        ),
      );
    }

    if (!isMine) {
      messageContent = RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: const Duration(seconds: 1)),
            (instance) => instance.onLongPress = () {
              setState(() {
                _showReplay = true;
              });
            },
          ),
        },
        child: messageContent,
      );
    }

    final showDelivered = isMine && (message.status == 'delivered' || message.status == 'read');

    return Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.content == 'Hello')
          _buildDateSeparator('Mon, 18 May at 2:55 PM'),
        Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: messageContent,
        ),
        if (showDelivered && !isSticker)
          Padding(
            padding: const EdgeInsets.only(right: 18, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 2),
                const Text(
                  'Delivered',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    widget.onReply?.call();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        color: const Color(0xFF007AFF).withValues(alpha: 0.9),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Replay',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!isMine && _showReplay && !isSticker)
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    widget.onReply?.call();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_counterclockwise,
                        color: const Color(0xFF007AFF).withValues(alpha: 0.9),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        'Replay',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSticker(String assetPath) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      width: 110,
      height: 110,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        color: const Color(0xFFF2F2F7),
        colorBlendMode: BlendMode.multiply,
      ),
    );
  }

  Widget _buildReactionBadge(String reaction, bool isMine) {
    final isQuestion = reaction == '?';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main circle
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: isQuestion ? const Color(0xFF007AFF) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                spreadRadius: 0.5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            reaction,
            style: TextStyle(
              color: isQuestion ? Colors.white : Colors.black,
              fontSize: isQuestion ? 12 : 14,
              fontWeight: isQuestion ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        // Small tail bubble 1
        Positioned(
          bottom: -1,
          right: isMine ? -1 : null,
          left: isMine ? null : -1,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isQuestion ? const Color(0xFF007AFF) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Small tail bubble 2
        Positioned(
          bottom: -3,
          right: isMine ? -3 : null,
          left: isMine ? null : -3,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: isQuestion ? const Color(0xFF007AFF) : Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSeparator(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteCard(LocalMessage parent) {
    final isMine = widget.message.isMine;
    final displayName = parent.isMine ? 'You' : 'Them';

    return GestureDetector(
      onTap: widget.onParentMessageTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMine ? Colors.white : const Color(0xFF007AFF),
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: TextStyle(
                color: isMine ? Colors.white : const Color(0xFF007AFF),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              parent.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMine ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
