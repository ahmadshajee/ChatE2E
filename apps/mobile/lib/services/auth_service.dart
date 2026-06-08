// ============================================================
//  Auth Service
//  Handles email/password authentication with Supabase.
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get the current authenticated user
  User? get currentUser => _client.auth.currentUser;

  /// Get the current session
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of auth state changes
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': displayName ?? 'User',
      },
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;
}
