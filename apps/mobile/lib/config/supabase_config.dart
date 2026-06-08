// ============================================================
//  Supabase Configuration
//  Placeholder values — replace with real env vars before use.
// ============================================================

class SupabaseConfig {
  // ─── PLACEHOLDER VALUES ─────────────────────────────────
  // Replace these with your real Supabase project credentials
  // before running the app.
  static const String supabaseUrl = 'https://nzddduhyvgmzynligmup.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_bcK0kNlKrr38o9qWaZYuvA_89a8lLBV';

  // Edge Function base URL (auto-derived from supabaseUrl)
  static String get functionsUrl => '$supabaseUrl/functions/v1';
}
