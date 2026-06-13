// ============================================================
//  Thread Reply View
//  iMessage-style inline reply overlay.
//  Shows a blurred background, the original message pinned at
//  top, thread replies below, and an input bar at the bottom.
//  Tap outside or swipe down to dismiss.
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../database/app_database.dart';
import '../services/sound_service.dart';

class ThreadReplyView extends StatefulWidget {
  final LocalMessage parentMessage;
  final AppDatabase db;
  final String conversationId;
  final String peerName;
  final Future<void> Function(String content, String parentMessageId) onSendReply;

  const ThreadReplyView({
    super.key,
    required this.parentMessage,
    required this.db,
    required this.conversationId,
    required this.peerName,
    required this.onSendReply,
  });

  @override
  State<ThreadReplyView> createState() => _ThreadReplyViewState();
}

class _ThreadReplyViewState extends State<ThreadReplyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _animController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    SoundService().playSend();
    _textController.clear();
    setState(() => _hasText = false);

    await widget.onSendReply(text, widget.parentMessage.id);

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: _fadeAnim,
          builder: (context, child) {
            return Stack(
              children: [
                // Blurred background
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 25 * _fadeAnim.value,
                      sigmaY: 25 * _fadeAnim.value,
                    ),
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: 0.45 * _fadeAnim.value),
                    ),
                  ),
                ),

                // Thread content card
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: GestureDetector(
                        onTap: () {}, // Prevent tap-through
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 50,
                            left: 12,
                            right: 12,
                            bottom: bottomPadding > 0
                                ? bottomPadding + 8
                                : MediaQuery.of(context).padding.bottom + 12,
                          ),
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight: screenSize.height * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header bar
                                  _buildHeader(),

                                  // Divider
                                  Container(
                                    height: 0.5,
                                    color: const Color(0xFFE5E5EA),
                                  ),

                                  // Parent message + replies
                                  Flexible(
                                    child: _buildThreadContent(),
                                  ),

                                  // Divider
                                  Container(
                                    height: 0.5,
                                    color: const Color(0xFFE5E5EA),
                                  ),

                                  // Input bar
                                  _buildInputBar(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: _dismiss,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          const Spacer(),
          // Title
          const Text(
            'Thread',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Placeholder for balance
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  // ── Thread Content (parent + replies) ──────────────────────

  Widget _buildThreadContent() {
    return StreamBuilder<List<LocalMessage>>(
      stream: widget.db.watchThreadReplies(widget.parentMessage.id),
      builder: (context, snapshot) {
        final replies = snapshot.data ?? [];

        return ListView(
          controller: _scrollController,
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Parent message (the original)
            _buildThreadBubble(
              widget.parentMessage,
              isParent: true,
            ),

            // Thread reply count indicator
            if (replies.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: const Color(0xFFE5E5EA),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: const Color(0xFFE5E5EA),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Replies
            ...replies.map((reply) => _buildThreadBubble(reply)),
          ],
        );
      },
    );
  }

  Widget _buildThreadBubble(LocalMessage message, {bool isParent = false}) {
    final isMine = message.isMine;

    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 48 : 12,
        right: isMine ? 12 : 48,
        top: isParent ? 4 : 3,
        bottom: isParent ? 4 : 3,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isMine
                ? const Color(0xFF007AFF)
                : const Color(0xFFE5E5EA),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black,
                  fontSize: 15,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              // Timestamp
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTime(message.sentAt),
                  style: TextStyle(
                    color: isMine
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF8E8E93),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // ── Input Bar ─────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Reply in thread...',
                  hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: (text) {
                  setState(() => _hasText = text.trim().isNotEmpty);
                },
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),

          // Send button
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
    );
  }
}
