// ============================================================
//  App Widget
//  MaterialApp with auth-aware routing.
//  Passes local database to screens.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database/app_database.dart';
import 'screens/auth_screen.dart';
import 'screens/chat_list_screen.dart';

class ChatizyApp extends StatelessWidget {
  final AppDatabase db;

  const ChatizyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatizy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B141A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A884),
          secondary: Color(0xFF00CF93),
          surface: Color(0xFF111B21),
          error: Color(0xFFEA4335),
        ),
        fontFamily: 'Inter',
      ),
      home: _AuthGate(db: db),
    );
  }
}

/// Listens to Supabase auth state and routes accordingly.
class _AuthGate extends StatelessWidget {
  final AppDatabase db;

  const _AuthGate({required this.db});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0B141A),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00A884),
              ),
            ),
          );
        }

        // Check if user is signed in
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return ChatListScreen(db: db);
        }

        return const AuthScreen();
      },
    );
  }
}
