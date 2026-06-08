// ============================================================
//  Landing Page — Redirects to /chat or /auth
// ============================================================

import { redirect } from "next/navigation";
import { createServerSupabaseClient } from "@/lib/supabase/server";

export default async function Home() {
  const supabase = await createServerSupabaseClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    redirect("/chat");
  } else {
    redirect("/auth");
  }
}
