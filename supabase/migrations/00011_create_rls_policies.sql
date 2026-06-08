-- ============================================================
--  Migration 00011: Row Level Security (RLS) Policies
--  Comprehensive RLS for all E2EE tables.
-- ============================================================

-- ╔════════════════════════════════════════════════════════════╗
-- ║  Enable RLS on all tables                                  ║
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  users                                                     ║
-- ╚════════════════════════════════════════════════════════════╝

-- Any authenticated user can read profiles (for user discovery / prekey fetch)
DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;
CREATE POLICY "users_select_authenticated"
  ON public.users FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Users can only update their own profile
DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- INSERT is handled by the trigger (SECURITY DEFINER), not direct client access
-- But we allow it for completeness with own-row check
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  devices                                                   ║
-- ╚════════════════════════════════════════════════════════════╝

-- Users can read any active device (needed to fetch prekey bundles for encryption)
DROP POLICY IF EXISTS "devices_select_authenticated" ON public.devices;
CREATE POLICY "devices_select_authenticated"
  ON public.devices FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Users can only insert their own devices
DROP POLICY IF EXISTS "devices_insert_own" ON public.devices;
CREATE POLICY "devices_insert_own"
  ON public.devices FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can only update their own devices
DROP POLICY IF EXISTS "devices_update_own" ON public.devices;
CREATE POLICY "devices_update_own"
  ON public.devices FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can only delete their own devices
DROP POLICY IF EXISTS "devices_delete_own" ON public.devices;
CREATE POLICY "devices_delete_own"
  ON public.devices FOR DELETE
  USING (auth.uid() = user_id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  one_time_prekeys                                          ║
-- ╚════════════════════════════════════════════════════════════╝

-- Any authenticated user can read prekeys (needed for session init)
DROP POLICY IF EXISTS "otpk_select_authenticated" ON public.one_time_prekeys;
CREATE POLICY "otpk_select_authenticated"
  ON public.one_time_prekeys FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Users can only insert prekeys for their own devices
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

-- Users can only update prekeys for their own devices
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

-- Users can only delete prekeys for their own devices
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  conversations                                             ║
-- ╚════════════════════════════════════════════════════════════╝

-- Users can only see conversations they are a member of
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

-- Authenticated users can create conversations
DROP POLICY IF EXISTS "conversations_insert_authenticated" ON public.conversations;
CREATE POLICY "conversations_insert_authenticated"
  ON public.conversations FOR INSERT
  WITH CHECK (auth.uid() = created_by);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  conversation_members                                      ║
-- ╚════════════════════════════════════════════════════════════╝

-- Members can see participants of their conversations
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

-- Authenticated users can add members (for starting conversations)
DROP POLICY IF EXISTS "cm_insert_authenticated" ON public.conversation_members;
CREATE POLICY "cm_insert_authenticated"
  ON public.conversation_members FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Members can update their own membership (e.g., leave)
DROP POLICY IF EXISTS "cm_update_own" ON public.conversation_members;
CREATE POLICY "cm_update_own"
  ON public.conversation_members FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ╔════════════════════════════════════════════════════════════╗
-- ║  device_envelopes                                          ║
-- ╚════════════════════════════════════════════════════════════╝

-- Target device owner can read their envelopes
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

-- Sender device owner can also read their sent envelopes (for status tracking)
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

-- Sender device owner can insert envelopes
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

-- Target device owner can update status (delivered, acknowledged)
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  media_objects                                             ║
-- ╚════════════════════════════════════════════════════════════╝

-- Conversation members can read media objects
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

-- Authenticated uploaders can insert media objects
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  device_sync_cursors                                       ║
-- ╚════════════════════════════════════════════════════════════╝

-- Users can only manage their own device's sync cursor
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  linked_device_sessions                                    ║
-- ╚════════════════════════════════════════════════════════════╝

-- Primary or linked device owner can read their sessions
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

-- Primary device owner can create link sessions
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

-- Primary or linked device owner can update sessions (approve/revoke)
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


-- ╔════════════════════════════════════════════════════════════╗
-- ║  delivery_events                                           ║
-- ╚════════════════════════════════════════════════════════════╝

-- Sender or target device owner can read delivery events
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

-- Target device owner can insert delivery events
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
-- ║  Supabase Realtime — Enable for envelope routing           ║
-- ╚════════════════════════════════════════════════════════════╝

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
END $$;

-- Enable realtime for device_envelopes (for push-based message delivery)
ALTER PUBLICATION supabase_realtime ADD TABLE public.device_envelopes;
-- Enable realtime for delivery_events (for receipt propagation)
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_events;
-- Enable realtime for linked_device_sessions (for QR linking status updates)
ALTER PUBLICATION supabase_realtime ADD TABLE public.linked_device_sessions;
