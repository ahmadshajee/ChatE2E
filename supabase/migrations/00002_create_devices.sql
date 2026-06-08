-- ============================================================
--  Migration 00002: Create devices table
--  One row per physical/browser device per user.
--  Stores signed prekey material for X3DH key agreement.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.devices (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                 UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  device_type             TEXT NOT NULL CHECK (device_type IN ('mobile', 'web', 'desktop')),
  platform                TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'windows', 'macos', 'linux')),
  push_token              TEXT,  -- FCM/APNs token, set later
  signed_prekey_public    TEXT NOT NULL,  -- Base64-encoded X25519 signed prekey
  signed_prekey_signature TEXT NOT NULL,  -- Base64-encoded Ed25519 signature
  signed_prekey_id        INTEGER NOT NULL,
  is_active               BOOLEAN NOT NULL DEFAULT true,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON public.devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_user_active ON public.devices(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON public.devices(last_seen_at);
