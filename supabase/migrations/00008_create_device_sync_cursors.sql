-- ============================================================
--  Migration 00008: Create device_sync_cursors table
--  Tracks last-processed envelope per device for resume/recovery.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.device_sync_cursors (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id        UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  last_envelope_id UUID REFERENCES public.device_envelopes(id) ON DELETE SET NULL,
  last_synced_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(device_id)
);

-- Index
CREATE INDEX IF NOT EXISTS idx_dsc_device ON public.device_sync_cursors(device_id);
