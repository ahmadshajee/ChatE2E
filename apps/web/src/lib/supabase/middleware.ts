// ============================================================
//  Supabase Middleware Helper
//  Refreshes the auth session on every request.
// ============================================================

import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";

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

export async function updateSession(request: NextRequest) {
  // If Supabase is not configured yet (placeholder env vars),
  // skip session refresh and allow all routes.
  if (!isSupabaseConfigured()) {
    return NextResponse.next({ request });
  }

  let supabaseResponse = NextResponse.next({
    request,
  });

  const supabase = createServerClient(supabaseUrl, supabaseAnonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) =>
          request.cookies.set(name, value)
        );
        supabaseResponse = NextResponse.next({
          request,
        });
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options)
        );
      },
    },
  });

  // IMPORTANT: Do NOT run supabase.auth.getSession() — it won't refresh the token.
  // Only getUser() sends a request to the Supabase Auth server to revalidate.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Redirect unauthenticated users to /auth (except when already on /auth)
  if (
    !user &&
    !request.nextUrl.pathname.startsWith("/auth") &&
    !request.nextUrl.pathname.startsWith("/api")
  ) {
    const url = request.nextUrl.clone();
    url.pathname = "/auth";
    return NextResponse.redirect(url);
  }

  // Redirect authenticated users away from /auth
  if (user && request.nextUrl.pathname.startsWith("/auth")) {
    const url = request.nextUrl.clone();
    url.pathname = "/chat";
    return NextResponse.redirect(url);
  }

  return supabaseResponse;
}

