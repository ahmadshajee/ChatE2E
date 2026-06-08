// ============================================================
//  Main Entry Point
//  Initializes Supabase, local database, and crypto services.
// ============================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'database/app_database.dart';
import 'app.dart';

/// Global database instance
late final AppDatabase appDatabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database (Drift/SQLite)
  appDatabase = AppDatabase();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(ChatizyApp(db: appDatabase));
}
