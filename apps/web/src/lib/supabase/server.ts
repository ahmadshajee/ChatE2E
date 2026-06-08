// ============================================================
//  Supabase Server Client
//  Used in Server Components, Route Handlers, Server Actions.
// ============================================================

import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL ?? "";
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? "";

/** Check if Supabase env vars are real (not placeholders) */
function isSupabaseConfigured(): boolean {
  return (
    supabaseUrl.startsWith("http") &&
    !supabaseUrl.includes("YOUR_") &&
    supabaseAnonKey.length > 0 &&
    !supabaseAnonKey.includes("YOUR_")
  );
}

export async function createServerSupabaseClient() {
  const cookieStore = await cookies();

  // Use placeholder URL during build if env vars aren't configured
  const url = isSupabaseConfigured() ? supabaseUrl : "https://placeholder.supabase.co";
  const key = isSupabaseConfigured() ? supabaseAnonKey : "placeholder-anon-key";

  return createServerClient(url, key, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          cookiesToSet.forEach(({ name, value, options }) =>
            cookieStore.set(name, value, options)
          );
        } catch {
          // The `setAll` method was called from a Server Component.
          // This can be ignored if you have middleware refreshing user sessions.
        }
      },
    },
  });
}
