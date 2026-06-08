-- ============================================================
--  Migration 00009: Create linked_device_sessions table
--  QR-based linking state machine for multi-device support.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.linked_device_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_device_id     UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  linked_device_id      UUID REFERENCES public.devices(id) ON DELETE SET NULL,  -- NULL until approved
  session_token         TEXT NOT NULL UNIQUE,  -- Random token embedded in QR code
  status                TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'revoked', 'expired')),
  qr_payload_encrypted  TEXT,  -- Encrypted bootstrap payload (nullable)
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_at           TIMESTAMPTZ,
  expires_at            TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '5 minutes')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_lds_primary ON public.linked_device_sessions(primary_device_id);
CREATE INDEX IF NOT EXISTS idx_lds_linked ON public.linked_device_sessions(linked_device_id);
CREATE INDEX IF NOT EXISTS idx_lds_token ON public.linked_device_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_lds_status ON public.linked_device_sessions(status);
CREATE INDEX IF NOT EXISTS idx_lds_expires ON public.linked_device_sessions(expires_at);
