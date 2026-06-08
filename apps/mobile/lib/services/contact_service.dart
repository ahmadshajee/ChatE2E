// ============================================================
//  Contact Service
//  Searches for users in the Supabase `users` table.
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_model.dart';

class ContactService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Search users by display name (case-insensitive partial match).
  /// Excludes the current user from results.
  Future<List<ContactModel>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _client
        .from('users')
        .select('id, display_name, avatar_url, identity_public_key')
        .ilike('display_name', '%${query.trim()}%')
        .neq('id', currentUserId)
        .limit(20);

    return (response as List)
        .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single user by ID.
  Future<ContactModel?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('id, display_name, avatar_url, identity_public_key')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return ContactModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Get all registered users (for initial discovery).
  Future<List<ContactModel>> getAllUsers() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return [];

    final response = await _client
        .from('users')
        .select('id, display_name, avatar_url, identity_public_key')
        .neq('id', currentUserId)
        .order('display_name')
        .limit(50);

    return (response as List)
        .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
