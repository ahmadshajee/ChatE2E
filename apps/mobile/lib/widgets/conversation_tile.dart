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
  final bool isSelectionMode;
  final bool isSelected;
  final bool isPinMode;
  final bool isPinned;
  final VoidCallback? onPinTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.isPinMode = false,
    this.isPinned = false,
    this.onPinTap,
  });

  bool _isBusinessConversation(String name) {
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleanName.isEmpty) return false;
    return cleanName == cleanName.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(conversation.peerDisplayName);
    final hasUnread = conversation.unreadCount > 0;
    final isBusiness = _isBusinessConversation(conversation.peerDisplayName);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isSelectionMode)
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF007AFF) : const Color(0xFFC7C7CC),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),

            // iOS unread indicator blue dot
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: hasUnread ? const Color(0xFF007AFF) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),

            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: isBusiness ? BorderRadius.circular(11) : null,
                shape: isBusiness ? BoxShape.rectangle : BoxShape.circle,
                gradient: isBusiness
                    ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFB4C2E1), Color(0xFF8699C2)],
                      )
                    : null,
                color: isBusiness ? null : const Color(0xFF8C9EC5),
              ),
              child: Center(
                child: isBusiness
                    ? const Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 26,
                      )
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Name + last message + time/chevron
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Name
                      Expanded(
                        child: Text(
                          conversation.peerDisplayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Time/Date + Chevron or Pinned Button
                      if (isPinMode)
                        GestureDetector(
                          onTap: onPinTap,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isPinned ? const Color(0xFFFFCC00) : const Color(0xFFE5E5EA),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.push_pin_rounded,
                              color: isPinned ? Colors.white : const Color(0xFF8E8E93),
                              size: 16,
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (conversation.lastMessageAt != null)
                              Text(
                                _formatTime(conversation.lastMessageAt!),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFFC7C7CC),
                              size: 16,
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Last Message Snippet (2 lines)
                  Text(
                    conversation.lastMessage ?? 'No messages yet',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
      return DateFormat('dd/MM/yy').format(time);
    }
  }
}
