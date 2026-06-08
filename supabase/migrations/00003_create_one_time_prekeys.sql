-- ============================================================
--  Migration 00003: Create one_time_prekeys table
--  Pool of one-time prekeys per device, consumed during
--  X3DH session initialization.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.one_time_prekeys (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id   UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  prekey_id   INTEGER NOT NULL,
  public_key  TEXT NOT NULL,  -- Base64-encoded X25519 public key
  is_consumed BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(device_id, prekey_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_otpk_device_id ON public.one_time_prekeys(device_id);
CREATE INDEX IF NOT EXISTS idx_otpk_available ON public.one_time_prekeys(device_id, is_consumed) WHERE NOT is_consumed;
