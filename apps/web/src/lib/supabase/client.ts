// ============================================================
//  Supabase Browser Client
//  Used in Client Components (runs in the browser).
// ============================================================

import { createBrowserClient } from "@supabase/ssr";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/** Check if Supabase env vars are real (not placeholders) */
export function isSupabaseConfigured(): boolean {
  return (
    supabaseUrl.startsWith("http") &&
    !supabaseUrl.includes("YOUR_") &&
    supabaseAnonKey.length > 0 &&
    !supabaseAnonKey.includes("YOUR_")
  );
}

export function createClient() {
  if (!isSupabaseConfigured()) {
    // Return a dummy client during build/development without real env vars.
    // This will fail at runtime but allows the app to compile.
    return createBrowserClient(
      "https://placeholder.supabase.co",
      "placeholder-anon-key"
    );
  }
  return createBrowserClient(supabaseUrl, supabaseAnonKey);
}
