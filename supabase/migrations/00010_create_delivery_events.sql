-- ============================================================
--  Migration 00010: Create delivery_events table
--  Receipt tracking (delivered, read, played).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.delivery_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  envelope_id UUID NOT NULL REFERENCES public.device_envelopes(id) ON DELETE CASCADE,
  device_id   UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL CHECK (event_type IN ('delivered', 'read', 'played')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- One event type per envelope per device
  UNIQUE(envelope_id, device_id, event_type)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_devt_envelope ON public.delivery_events(envelope_id);
CREATE INDEX IF NOT EXISTS idx_devt_device ON public.delivery_events(device_id);
