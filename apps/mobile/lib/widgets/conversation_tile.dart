// ============================================================
//  Conversation Tile Widget
//  A single row in the chat list showing peer info, last message,
//  timestamp, and unread badge.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';

class ConversationTile extends StatelessWidget {
  final LocalConversation conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(conversation.peerDisplayName);
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _avatarColors(conversation.peerUserId),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.peerDisplayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            color: const Color(0xFFE9EDEF),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.lastMessageAt != null)
                        Text(
                          _formatTime(conversation.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? const Color(0xFF00A884)
                                : const Color(0xFF8696A0),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? 'No messages yet',
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? const Color(0xFFD1D7DB)
                                : const Color(0xFF8696A0),
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00A884),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat('MM/dd/yy').format(time);
    }
  }

  List<Color> _avatarColors(String id) {
    final hash = id.hashCode;
    final colors = [
      [const Color(0xFF00A884), const Color(0xFF00CF93)],
      [const Color(0xFF5856D6), const Color(0xFF7B73F3)],
      [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
      [const Color(0xFF4ECDC4), const Color(0xFF6EE7DE)],
      [const Color(0xFFFFA726), const Color(0xFFFFCC80)],
      [const Color(0xFF42A5F5), const Color(0xFF90CAF9)],
    ];
    return colors[hash.abs() % colors.length];
  }
}
