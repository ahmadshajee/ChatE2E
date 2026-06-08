// ============================================================
//  Message Bubble Widget
//  Chat bubble with directional styling, timestamps,
//  and delivery status indicators.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';

class MessageBubble extends StatelessWidget {
  final LocalMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          left: isMine ? 60 : 8,
          right: isMine ? 8 : 60,
          top: 2,
          bottom: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? const Color(0xFF005C4B)
              : const Color(0xFF1F2C34),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message text
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // Time + status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(message.sentAt),
                  style: const TextStyle(
                    color: Color(0xFF8696A0),
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(
          Icons.access_time,
          size: 14,
          color: Color(0xFF8696A0),
        );
      case 'sent':
        return const Icon(
          Icons.check,
          size: 14,
          color: Color(0xFF8696A0),
        );
      case 'delivered':
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF8696A0),
        );
      case 'read':
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Color(0xFF53BDEB),
        );
      case 'failed':
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Color(0xFFF87171),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
