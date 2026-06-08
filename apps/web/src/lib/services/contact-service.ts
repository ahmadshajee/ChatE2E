// ============================================================
//  Web Contact Service
//  Search for users in the Supabase users table.
// ============================================================

import { createClient } from "@/lib/supabase/client";

export interface Contact {
  id: string;
  displayName: string;
  email?: string;
  avatarUrl?: string;
  identityPublicKey?: string;
}

export async function searchUsers(query: string): Promise<Contact[]> {
  if (!query.trim()) return [];

  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data } = await supabase
    .from("users")
    .select("id, display_name, avatar_url, identity_public_key")
    .ilike("display_name", `%${query.trim()}%`)
    .neq("id", user.id)
    .limit(20);

  return (data ?? []).map((u: any) => ({
    id: u.id,
    displayName: u.display_name ?? "User",
    avatarUrl: u.avatar_url,
    identityPublicKey: u.identity_public_key,
  }));
}

export async function getAllUsers(): Promise<Contact[]> {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data } = await supabase
    .from("users")
    .select("id, display_name, avatar_url, identity_public_key")
    .neq("id", user.id)
    .order("display_name")
    .limit(50);

  return (data ?? []).map((u: any) => ({
    id: u.id,
    displayName: u.display_name ?? "User",
    avatarUrl: u.avatar_url,
    identityPublicKey: u.identity_public_key,
  }));
}
