// ============================================================
//  Message Bubble Widget
//  Chat bubble with iMessage-style directional styling, colors,
//  tapback reactions, Memoji stickers, delivery status, and
//  long-press context menu with emoji reactions + action menu.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';

class MessageBubble extends StatefulWidget {
  final LocalMessage message;
  final LocalMessage? parentMessage;
  final VoidCallback? onReply;
  final VoidCallback? onParentMessageTap;
  final VoidCallback? onDelete;
  final VoidCallback? onForward;
  final Function(String? emoji)? onReaction;

  const MessageBubble({
    super.key,
    required this.message,
    this.parentMessage,
    this.onReply,
    this.onParentMessageTap,
    this.onDelete,
    this.onForward,
    this.onReaction,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // Key to get the bubble's global position for the overlay
  final GlobalKey _bubbleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMine = message.isMine;
    final isSticker = message.content == '[sticker:dino]';

    // Reactions loaded from database column
    final String? reaction = message.reaction;

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
              key: _bubbleKey,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF007AFF)
                    : const Color(0xFFE5E5EA),
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

    // Wrap with GestureDetector for long-press context menu
    if (!isSticker) {
      messageContent = GestureDetector(
        onLongPress: () => _showContextMenu(context),
        child: messageContent,
      );
    }

    final showDelivered =
        isMine && (message.status == 'delivered' || message.status == 'read');

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
              ],
            ),
          ),
      ],
    );
  }

  // ── Long-press context menu (iMessage style) ──────────────

  void _showContextMenu(BuildContext context) {
    HapticFeedback.mediumImpact();

    final message = widget.message;
    final isMine = message.isMine;

    // Get the bubble's position on screen
    final RenderBox? renderBox =
        _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final bubbleSize = renderBox.size;
    final bubblePosition = renderBox.localToGlobal(Offset.zero);

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _IMessageContextMenu(
            message: message,
            isMine: isMine,
            bubbleSize: bubbleSize,
            bubblePosition: bubblePosition,
            animation: animation,
            parentMessage: widget.parentMessage,
            currentReaction: message.reaction,
            onReply: () {
              Navigator.of(context).pop();
              widget.onReply?.call();
            },
            onCopy: () {
              Clipboard.setData(ClipboardData(text: message.content));
              Navigator.of(context).pop();
            },
            onReaction: (emoji) {
              Navigator.of(context).pop();
              final currentReaction = message.reaction;
              final newReaction = currentReaction == emoji ? null : emoji;
              widget.onReaction?.call(newReaction);
            },
            onDismiss: () {
              Navigator.of(context).pop();
            },
            onDelete: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            onForward: () {
              Navigator.of(context).pop();
              widget.onForward?.call();
            },
          );
        },
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

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
                color:
                    isMine ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  iMessage Context Menu (Full-Screen Overlay)
// ════════════════════════════════════════════════════════════

class _IMessageContextMenu extends StatefulWidget {
  final LocalMessage message;
  final bool isMine;
  final Size bubbleSize;
  final Offset bubblePosition;
  final Animation<double> animation;
  final LocalMessage? parentMessage;
  final String? currentReaction;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final Function(String? emoji) onReaction;
  final VoidCallback onDismiss;
  final VoidCallback onDelete;
  final VoidCallback onForward;

  const _IMessageContextMenu({
    required this.message,
    required this.isMine,
    required this.bubbleSize,
    required this.bubblePosition,
    required this.animation,
    this.parentMessage,
    this.currentReaction,
    required this.onReply,
    required this.onCopy,
    required this.onReaction,
    required this.onDismiss,
    required this.onDelete,
    required this.onForward,
  });

  @override
  State<_IMessageContextMenu> createState() => _IMessageContextMenuState();
}

class _IMessageContextMenuState extends State<_IMessageContextMenu> {
  static const _reactions = ['❤️', '👍', '👎', '😂', '‼️', '❓', '😢', '😡'];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMine = widget.isMine;

    // Calculate bubble position for the overlay
    // We need to position the message bubble in the overlay at its original position
    // but adjust if needed so the reaction bar + menu fit on screen
    double bubbleTop = widget.bubblePosition.dy;
    final menuHeight = 300.0; // approximate total height of reaction bar + menu
    final reactionBarHeight = 52.0;
    final availableAbove = bubbleTop - MediaQuery.of(context).padding.top;
    final availableBelow = screenSize.height -
        bubbleTop -
        widget.bubbleSize.height -
        MediaQuery.of(context).padding.bottom;

    // Determine if menu should go above or below the bubble
    bool menuBelow = availableBelow >= menuHeight;

    // If not enough space below, try adjusting
    if (!menuBelow && availableAbove < menuHeight) {
      // Center it vertically
      bubbleTop = (screenSize.height - widget.bubbleSize.height) / 2;
      menuBelow = true;
    }

    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: widget.animation,
        builder: (context, child) {
          final opacity = widget.animation.value;
          return GestureDetector(
            onTap: widget.onDismiss,
            child: Stack(
              children: [
                // Blurred background
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 20 * opacity,
                      sigmaY: 20 * opacity,
                    ),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4 * opacity),
                    ),
                  ),
                ),

                // Emoji reaction bar — positioned above the bubble
                Positioned(
                  top: (menuBelow ? bubbleTop - reactionBarHeight - 8 : bubbleTop - reactionBarHeight - 8)
                      .clamp(MediaQuery.of(context).padding.top + 8, screenSize.height - 100),
                  left: isMine ? null : 12,
                  right: isMine ? 12 : null,
                  child: FadeTransition(
                    opacity: widget.animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: widget.animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: _buildReactionBar(),
                    ),
                  ),
                ),

                // The message bubble itself (clone)
                Positioned(
                  top: bubbleTop,
                  left: isMine ? null : widget.bubblePosition.dx,
                  right: isMine
                      ? screenSize.width -
                          widget.bubblePosition.dx -
                          widget.bubbleSize.width
                      : null,
                  child: FadeTransition(
                    opacity: widget.animation,
                    child: _buildBubbleClone(),
                  ),
                ),

                // Action menu — positioned below the bubble
                Positioned(
                  top: (menuBelow
                          ? bubbleTop + widget.bubbleSize.height + 8
                          : bubbleTop - menuHeight - reactionBarHeight - 16)
                      .clamp(
                    MediaQuery.of(context).padding.top + reactionBarHeight + 60,
                    screenSize.height - 200,
                  ),
                  left: isMine ? null : 12,
                  right: isMine ? 12 : null,
                  child: FadeTransition(
                    opacity: widget.animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: widget.animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: _buildActionMenu(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Emoji Reaction Bar ─────────────────────────────────────

  Widget _buildReactionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _reactions.map((emoji) {
          final isSelected = widget.currentReaction == emoji;
          return GestureDetector(
            onTap: () => widget.onReaction(emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007AFF).withValues(alpha: 0.3)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bubble Clone (for the overlay) ─────────────────────────

  Widget _buildBubbleClone() {
    final isMine = widget.isMine;
    return Container(
      width: widget.bubbleSize.width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(isMine ? 20 : 6),
          bottomRight: Radius.circular(isMine ? 6 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.parentMessage != null) ...[
            _buildOverlayQuoteCard(widget.parentMessage!),
          ],
          Text(
            widget.message.content,
            style: TextStyle(
              color: isMine ? Colors.white : Colors.black,
              fontSize: 16,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayQuoteCard(LocalMessage parent) {
    final isMine = widget.isMine;
    final displayName = parent.isMine ? 'You' : 'Them';
    return Container(
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
              color: isMine
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Menu ────────────────────────────────────────────

  Widget _buildActionMenu() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(
              icon: CupertinoIcons.reply,
              label: 'Reply',
              onTap: widget.onReply,
            ),
            _menuDivider(),
            _buildMenuItem(
              icon: CupertinoIcons.smiley,
              label: 'Attach Sticker',
              onTap: () => Navigator.of(context).pop(),
            ),
            _menuDivider(),
            _buildMenuItem(
              icon: CupertinoIcons.doc_on_doc,
              label: 'Copy',
              onTap: widget.onCopy,
            ),
            _menuDivider(),
            _buildMenuItem(
              icon: CupertinoIcons.arrowshape_turn_up_right,
              label: 'Forward',
              onTap: widget.onForward,
            ),
            _menuDivider(),
            _buildMenuItem(
              icon: CupertinoIcons.text_cursor,
              label: 'Select',
              onTap: () => Navigator.of(context).pop(),
            ),
            _menuDivider(),
            _buildMenuItem(
              icon: CupertinoIcons.trash,
              label: 'Delete',
              onTap: widget.onDelete,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() {
    return Container(
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return _ContextMenuItem(
      icon: icon,
      label: label,
      onTap: onTap,
      isDestructive: isDestructive,
    );
  }
}

// ── Context Menu Item with Highlight ──────────────────────────

class _ContextMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ContextMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _isHighlighted = false;

  @override
  Widget build(BuildContext context) {
    final displayColor = widget.isDestructive ? CupertinoColors.systemRed : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isHighlighted = true),
      onTapUp: (_) => setState(() => _isHighlighted = false),
      onTapCancel: () => setState(() => _isHighlighted = false),
      onTap: widget.onTap,
      child: Container(
        color:
            _isHighlighted ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: displayColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: displayColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
