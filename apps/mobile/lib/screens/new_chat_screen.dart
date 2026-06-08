// ============================================================
//  New Chat Screen
//  Search for users and start a new direct conversation.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../services/contact_service.dart';
import '../services/conversation_service.dart';
import '../database/app_database.dart';
import 'chat_room_screen.dart';

class NewChatScreen extends StatefulWidget {
  final AppDatabase db;

  const NewChatScreen({super.key, required this.db});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ContactService _contactService = ContactService();
  late final ConversationService _conversationService;
  final _searchController = TextEditingController();

  List<ContactModel> _results = [];
  bool _isLoading = false;
  bool _isCreating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _conversationService = ConversationService(widget.db);
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _contactService.getAllUsers();
      if (mounted) setState(() => _results = users);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (query.trim().isEmpty) {
        _loadAllUsers();
        return;
      }
      setState(() => _isLoading = true);
      try {
        final results = await _contactService.searchUsers(query);
        if (mounted) setState(() => _results = results);
      } catch (_) {}
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _startConversation(ContactModel contact) async {
    setState(() => _isCreating = true);
    try {
      final conversationId =
          await _conversationService.getOrCreateDirectConversation(contact);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              conversationId: conversationId,
              peerName: contact.displayName,
              db: widget.db,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create conversation: $e'),
            backgroundColor: const Color(0xFFEA4335),
          ),
        );
      }
    }
    if (mounted) setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2C34),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE9EDEF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Chat',
          style: TextStyle(
            color: Color(0xFFE9EDEF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF111B21),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: Color(0xFFE9EDEF),
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search by name...',
                  hintStyle: TextStyle(color: Color(0xFF8696A0)),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF8696A0),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay for conversation creation
          if (_isCreating)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00A884),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating conversation...',
                    style: TextStyle(color: Color(0xFF8696A0)),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00A884),
                    ),
                  )
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Color(0xFF8696A0)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final contact = _results[index];
                          return _buildContactTile(contact);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(ContactModel contact) {
    return InkWell(
      onTap: _isCreating ? null : () => _startConversation(contact),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _avatarColors(contact.id),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  contact.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE9EDEF),
                    ),
                  ),
                  if (contact.email != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact.email!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8696A0),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // E2EE indicator
            Icon(
              Icons.lock_outline,
              size: 16,
              color: const Color(0xFF00A884).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
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
