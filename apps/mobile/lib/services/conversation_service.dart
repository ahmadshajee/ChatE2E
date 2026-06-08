// ============================================================
//  Conversation Service
//  Creates and fetches direct conversations.
//  Syncs server-side conversation metadata to local Drift DB.
// ============================================================

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../models/contact_model.dart';
import 'contact_service.dart';

class ConversationService {
  final SupabaseClient _client = Supabase.instance.client;
  final AppDatabase _db;
  final ContactService _contactService = ContactService();

  ConversationService(this._db);

  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Get or create a direct conversation with a peer user.
  /// Returns the conversation ID.
  Future<String> getOrCreateDirectConversation(ContactModel peer) async {
    final userId = _currentUserId;
    if (userId == null) throw StateError('Not authenticated');

    // 1. Check local DB first
    final localConv = await _db.findConversationByPeer(peer.id);
    if (localConv != null) return localConv.id;

    // 2. Check server for existing conversation between these two users
    final existingId = await _findExistingConversation(userId, peer.id);
    if (existingId != null) {
      // Cache locally
      await _db.upsertConversation(LocalConversationsCompanion(
        id: Value(existingId),
        peerUserId: Value(peer.id),
        peerDisplayName: Value(peer.displayName),
        peerEmail: Value(peer.email ?? ''),
        unreadCount: const Value(0),
      ));
      return existingId;
    }

    // 3. Create new conversation on server
    final convResponse = await _client
        .from('conversations')
        .insert({
          'type': 'direct',
          'created_by': userId,
        })
        .select('id')
        .single();

    final conversationId = convResponse['id'] as String;

    // 4. Add both members
    await _client.from('conversation_members').insert([
      {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'admin',
      },
      {
        'conversation_id': conversationId,
        'user_id': peer.id,
        'role': 'member',
      },
    ]);

    // 5. Cache locally
    await _db.upsertConversation(LocalConversationsCompanion(
      id: Value(conversationId),
      peerUserId: Value(peer.id),
      peerDisplayName: Value(peer.displayName),
      peerEmail: Value(peer.email ?? ''),
      unreadCount: const Value(0),
    ));

    return conversationId;
  }

  /// Find an existing direct conversation between two users on the server.
  Future<String?> _findExistingConversation(String userId, String peerUserId) async {
    try {
      // Find conversations where both users are members
      final myConversations = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userId)
          .isFilter('left_at', null);

      final myConvIds = (myConversations as List)
          .map((r) => r['conversation_id'] as String)
          .toList();

      if (myConvIds.isEmpty) return null;

      // Check which of those also have the peer
      final sharedConversations = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', peerUserId)
          .isFilter('left_at', null)
          .inFilter('conversation_id', myConvIds);

      if ((sharedConversations as List).isEmpty) return null;

      // Verify it's a 'direct' type conversation
      final convId = sharedConversations[0]['conversation_id'] as String;
      final conv = await _client
          .from('conversations')
          .select('id, type')
          .eq('id', convId)
          .eq('type', 'direct')
          .maybeSingle();

      return conv?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetch all conversations from the server and sync to local DB.
  Future<void> syncConversations() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      // Get all conversation memberships for the current user
      final memberships = await _client
          .from('conversation_members')
          .select('conversation_id')
          .eq('user_id', userId)
          .isFilter('left_at', null);

      final convIds = (memberships as List)
          .map((r) => r['conversation_id'] as String)
          .toList();

      if (convIds.isEmpty) return;

      // For each conversation, find the peer member
      for (final convId in convIds) {
        final members = await _client
            .from('conversation_members')
            .select('user_id')
            .eq('conversation_id', convId)
            .neq('user_id', userId);

        if ((members as List).isEmpty) continue;

        final peerUserId = members[0]['user_id'] as String;
        final peer = await _contactService.getUserById(peerUserId);
        if (peer == null) continue;

        // Upsert to local DB (preserve existing last_message if any)
        final existing = await _db.getConversation(convId);
        await _db.upsertConversation(LocalConversationsCompanion(
          id: Value(convId),
          peerUserId: Value(peerUserId),
          peerDisplayName: Value(peer.displayName),
          peerEmail: Value(peer.email ?? ''),
          lastMessage: Value(existing?.lastMessage),
          lastMessageAt: Value(existing?.lastMessageAt),
          unreadCount: Value(existing?.unreadCount ?? 0),
        ));
      }
    } catch (e) {
      // Sync failures are non-fatal — local data still works
      print('Conversation sync error: $e');
    }
  }

  /// Watch all local conversations as a stream.
  Stream<List<LocalConversation>> watchConversations() {
    return _db.watchConversations();
  }

  /// Get a conversation by ID.
  Future<LocalConversation?> getConversation(String id) {
    return _db.getConversation(id);
  }

  /// Reset unread count when user opens a conversation.
  Future<void> markAsRead(String conversationId) {
    return _db.resetUnreadCount(conversationId);
  }
}
