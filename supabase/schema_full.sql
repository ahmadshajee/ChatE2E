-- ============================================================
--  CHATIZY E2EE — Complete Database Schema
--  Paste this entire script into the Supabase SQL Editor
--  Project: https://nzddduhyvgmzynligmup.supabase.co
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ╔════════════════════════════════════════════════════════════╗
-- ║  1. USERS                                                  ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.users (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name        TEXT NOT NULL DEFAULT 'User',
  avatar_url          TEXT,
  identity_public_key TEXT,
  status              TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'deleted')),
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

-- Auto-create user profile on sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, display_name, avatar_url, created_at, updated_at)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'name',
      NEW.raw_user_meta_data->>'full_name',
      'User'
    ),
    NEW.raw_user_meta_data->>'avatar_url',
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    avatar_url   = COALESCE(EXCLUDED.avatar_url, public.users.avatar_url),
    updated_at   = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ╔════════════════════════════════════════════════════════════╗
-- ║  2. DEVICES                                                ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.devices (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  device_type             TEXT NOT NULL CHECK (device_type IN ('mobile', 'web', 'desktop')),
  platform                TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  push_token              TEXT,
  signed_prekey_public    TEXT NOT NULL,
  signed_prekey_signature TEXT NOT NULL,
  signed_prekey_id        INTEGER NOT NULL,
  is_active               BOOLEAN NOT NULL DEFAULT true,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_active ON public.devices(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON public.devices(last_seen_at);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  3. ONE-TIME PREKEYS                                       ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.one_time_prekeys (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id   UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  prekey_id   INTEGER NOT NULL,
  public_key  TEXT NOT NULL,
  is_consumed BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(device_id, prekey_id)
);

CREATE INDEX IF NOT EXISTS idx_otpk_device_id ON public.one_time_prekeys(device_id);
CREATE INDEX IF NOT EXISTS idx_otpk_available ON public.one_time_prekeys(device_id, is_consumed) WHERE NOT is_consumed;


-- ╔════════════════════════════════════════════════════════════╗
-- ║  4. CONVERSATIONS (routing metadata ONLY — no plaintext)   ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.conversations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type       TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_type ON public.conversations(type);

CREATE TRIGGER conversations_updated_at
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();


-- ╔════════════════════════════════════════════════════════════╗
-- ║  5. CONVERSATION MEMBERS                                   ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.conversation_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at         TIMESTAMPTZ,
  UNIQUE(conversation_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_cm_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_cm_user ON public.conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_cm_active ON public.conversation_members(user_id, conversation_id) WHERE left_at IS NULL;


-- ╔════════════════════════════════════════════════════════════╗
-- ║  6. DEVICE ENVELOPES (ciphertext ONLY — NEVER plaintext)   ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.device_envelopes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id   UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  target_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  client_message_id TEXT NOT NULL,
  ciphertext        TEXT NOT NULL,
  envelope_type     TEXT NOT NULL DEFAULT 'message' CHECK (envelope_type IN ('message', 'prekey_message', 'key_exchange')),
  status            TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'acknowledged')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at        TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days')
);

CREATE INDEX IF NOT EXISTS idx_de_target_status ON public.device_envelopes(target_device_id, status);
CREATE INDEX IF NOT EXISTS idx_de_target_pending ON public.device_envelopes(target_device_id, created_at)
  WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_de_conversation ON public.device_envelopes(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_de_sender ON public.device_envelopes(sender_device_id);
CREATE INDEX IF NOT EXISTS idx_de_client_msg ON public.device_envelopes(client_message_id);
CREATE INDEX IF NOT EXISTS idx_de_expires ON public.device_envelopes(expires_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_de_idempotent
  ON public.device_envelopes(client_message_id, target_device_id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  7. MEDIA OBJECTS (encrypted blob metadata — keys in       ║
-- ║     envelopes, NOT here)                                   ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.media_objects (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uploader_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  conversation_id     UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  storage_key         TEXT NOT NULL,
  content_type_hint   TEXT,
  byte_size           BIGINT NOT NULL DEFAULT 0,
  encryption_iv       TEXT NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_mo_conversation ON public.media_objects(conversation_id);
CREATE INDEX IF NOT EXISTS idx_mo_uploader ON public.media_objects(uploader_device_id);
CREATE INDEX IF NOT EXISTS idx_mo_storage_key ON public.media_objects(storage_key);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  8. DEVICE SYNC CURSORS                                    ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.device_sync_cursors (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id        UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  last_envelope_id UUID REFERENCES public.device_envelopes(id) ON DELETE SET NULL,
  last_synced_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(device_id)
);

CREATE INDEX IF NOT EXISTS idx_dsc_device ON public.device_sync_cursors(device_id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  9. LINKED DEVICE SESSIONS (QR linking state machine)      ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.linked_device_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_device_id     UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  linked_device_id      UUID REFERENCES public.devices(id) ON DELETE SET NULL,
  session_token         TEXT NOT NULL UNIQUE,
  status                TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'revoked', 'expired')),
  qr_payload_encrypted  TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at           TIMESTAMPTZ,
  expires_at            TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '5 minutes')
);

CREATE INDEX IF NOT EXISTS idx_lds_primary ON public.linked_device_sessions(primary_device_id);
CREATE INDEX IF NOT EXISTS idx_lds_linked ON public.linked_device_sessions(linked_device_id);
CREATE INDEX IF NOT EXISTS idx_lds_token ON public.linked_device_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_lds_status ON public.linked_device_sessions(status);
CREATE INDEX IF NOT EXISTS idx_lds_expires ON public.linked_device_sessions(expires_at);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  10. DELIVERY EVENTS (receipts)                            ║
-- ╚════════════════════════════════════════════════════════════╝

CREATE TABLE IF NOT EXISTS public.delivery_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  envelope_id UUID NOT NULL REFERENCES public.device_envelopes(id) ON DELETE CASCADE,
  device_id   UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL CHECK (event_type IN ('delivered', 'read', 'played')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(envelope_id, device_id, event_type)
);

CREATE INDEX IF NOT EXISTS idx_devt_envelope ON public.delivery_events(envelope_id);
CREATE INDEX IF NOT EXISTS idx_devt_device ON public.delivery_events(device_id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  11. ROW LEVEL SECURITY                                    ║
-- ╚════════════════════════════════════════════════════════════╝

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.one_time_prekeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_envelopes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_sync_cursors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.linked_device_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_events ENABLE ROW LEVEL SECURITY;

-- ── users ────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;
CREATE POLICY "users_select_authenticated"
  ON public.users FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ── devices ──────────────────────────────────────────────────
DROP POLICY IF EXISTS "devices_select_authenticated" ON public.devices;
CREATE POLICY "devices_select_authenticated"
  ON public.devices FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "devices_insert_own" ON public.devices;
CREATE POLICY "devices_insert_own"
  ON public.devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "devices_update_own" ON public.devices;
CREATE POLICY "devices_update_own"
  ON public.devices FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "devices_delete_own" ON public.devices;
CREATE POLICY "devices_delete_own"
  ON public.devices FOR DELETE
  USING (auth.uid() = user_id);

-- ── one_time_prekeys ─────────────────────────────────────────
DROP POLICY IF EXISTS "otpk_select_authenticated" ON public.one_time_prekeys;
CREATE POLICY "otpk_select_authenticated"
  ON public.one_time_prekeys FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "otpk_insert_own_device" ON public.one_time_prekeys;
CREATE POLICY "otpk_insert_own_device"
  ON public.one_time_prekeys FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = one_time_prekeys.device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "otpk_update_own_device" ON public.one_time_prekeys;
CREATE POLICY "otpk_update_own_device"
  ON public.one_time_prekeys FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = one_time_prekeys.device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "otpk_delete_own_device" ON public.one_time_prekeys;
CREATE POLICY "otpk_delete_own_device"
  ON public.one_time_prekeys FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = one_time_prekeys.device_id
        AND devices.user_id = auth.uid()
    )
  );

-- ── conversations ────────────────────────────────────────────
DROP POLICY IF EXISTS "conversations_select_member" ON public.conversations;
CREATE POLICY "conversations_select_member"
  ON public.conversations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members
      WHERE conversation_members.conversation_id = conversations.id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "conversations_insert_authenticated" ON public.conversations;
CREATE POLICY "conversations_insert_authenticated"
  ON public.conversations FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- ── conversation_members ─────────────────────────────────────
DROP POLICY IF EXISTS "cm_select_member" ON public.conversation_members;
CREATE POLICY "cm_select_member"
  ON public.conversation_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members cm
      WHERE cm.conversation_id = conversation_members.conversation_id
        AND cm.user_id = auth.uid()
        AND cm.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "cm_insert_authenticated" ON public.conversation_members;
CREATE POLICY "cm_insert_authenticated"
  ON public.conversation_members FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "cm_update_own" ON public.conversation_members;
CREATE POLICY "cm_update_own"
  ON public.conversation_members FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ── device_envelopes ─────────────────────────────────────────
DROP POLICY IF EXISTS "de_select_target" ON public.device_envelopes;
CREATE POLICY "de_select_target"
  ON public.device_envelopes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_envelopes.target_device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "de_select_sender" ON public.device_envelopes;
CREATE POLICY "de_select_sender"
  ON public.device_envelopes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_envelopes.sender_device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "de_insert_sender" ON public.device_envelopes;
CREATE POLICY "de_insert_sender"
  ON public.device_envelopes FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_envelopes.sender_device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "de_update_target" ON public.device_envelopes;
CREATE POLICY "de_update_target"
  ON public.device_envelopes FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_envelopes.target_device_id
        AND devices.user_id = auth.uid()
    )
  );

-- ── media_objects ────────────────────────────────────────────
DROP POLICY IF EXISTS "mo_select_member" ON public.media_objects;
CREATE POLICY "mo_select_member"
  ON public.media_objects FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversation_members
      WHERE conversation_members.conversation_id = media_objects.conversation_id
        AND conversation_members.user_id = auth.uid()
        AND conversation_members.left_at IS NULL
    )
  );

DROP POLICY IF EXISTS "mo_insert_authenticated" ON public.media_objects;
CREATE POLICY "mo_insert_authenticated"
  ON public.media_objects FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = media_objects.uploader_device_id
        AND devices.user_id = auth.uid()
    )
  );

-- ── device_sync_cursors ──────────────────────────────────────
DROP POLICY IF EXISTS "dsc_select_own" ON public.device_sync_cursors;
CREATE POLICY "dsc_select_own"
  ON public.device_sync_cursors FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_sync_cursors.device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "dsc_insert_own" ON public.device_sync_cursors;
CREATE POLICY "dsc_insert_own"
  ON public.device_sync_cursors FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_sync_cursors.device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "dsc_update_own" ON public.device_sync_cursors;
CREATE POLICY "dsc_update_own"
  ON public.device_sync_cursors FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = device_sync_cursors.device_id
        AND devices.user_id = auth.uid()
    )
  );

-- ── linked_device_sessions ───────────────────────────────────
DROP POLICY IF EXISTS "lds_select_owner" ON public.linked_device_sessions;
CREATE POLICY "lds_select_owner"
  ON public.linked_device_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE (devices.id = linked_device_sessions.primary_device_id
          OR devices.id = linked_device_sessions.linked_device_id)
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "lds_insert_primary" ON public.linked_device_sessions;
CREATE POLICY "lds_insert_primary"
  ON public.linked_device_sessions FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = linked_device_sessions.primary_device_id
        AND devices.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "lds_update_owner" ON public.linked_device_sessions;
CREATE POLICY "lds_update_owner"
  ON public.linked_device_sessions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE (devices.id = linked_device_sessions.primary_device_id
          OR devices.id = linked_device_sessions.linked_device_id)
        AND devices.user_id = auth.uid()
    )
  );

-- ── delivery_events ──────────────────────────────────────────
DROP POLICY IF EXISTS "devt_select_participant" ON public.delivery_events;
CREATE POLICY "devt_select_participant"
  ON public.delivery_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.device_envelopes de
      JOIN public.devices d ON (d.id = de.sender_device_id OR d.id = de.target_device_id)
      WHERE de.id = delivery_events.envelope_id
        AND d.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "devt_insert_target" ON public.delivery_events;
CREATE POLICY "devt_insert_target"
  ON public.delivery_events FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.devices
      WHERE devices.id = delivery_events.device_id
        AND devices.user_id = auth.uid()
    )
  );


-- ╔════════════════════════════════════════════════════════════╗
-- ║  12. SUPABASE REALTIME                                     ║
-- ╚════════════════════════════════════════════════════════════╝

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE public.device_envelopes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.linked_device_sessions;


-- ============================================================
--  DONE! You should now see 10 tables in the Table Editor:
--  users, devices, one_time_prekeys, conversations,
--  conversation_members, device_envelopes, media_objects,
--  device_sync_cursors, linked_device_sessions, delivery_events
--
--  NONE of these tables contain plaintext message content.
-- ============================================================
