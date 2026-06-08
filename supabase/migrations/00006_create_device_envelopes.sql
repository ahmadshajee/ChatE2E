-- ============================================================
--  Migration 00006: Create device_envelopes table
--  The CORE encrypted message routing table.
--  Stores ONLY ciphertext — NEVER plaintext message content.
--  Readable messages exist only on client devices.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.device_envelopes (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id   UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  target_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  client_message_id TEXT NOT NULL,  -- Client-generated idempotency key
  ciphertext        TEXT NOT NULL,  -- Base64-encoded encrypted payload — NEVER plaintext
  envelope_type     TEXT NOT NULL DEFAULT 'message' CHECK (envelope_type IN ('message', 'prekey_message', 'key_exchange')),
  status            TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'delivered', 'acknowledged')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at        TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '30 days')
);

-- Indexes for efficient queue fetching
CREATE INDEX IF NOT EXISTS idx_de_target_status ON public.device_envelopes(target_device_id, status);
CREATE INDEX IF NOT EXISTS idx_de_target_pending ON public.device_envelopes(target_device_id, created_at)
  WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_de_conversation ON public.device_envelopes(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_de_sender ON public.device_envelopes(sender_device_id);
CREATE INDEX IF NOT EXISTS idx_de_client_msg ON public.device_envelopes(client_message_id);
CREATE INDEX IF NOT EXISTS idx_de_expires ON public.device_envelopes(expires_at);

-- Idempotency constraint: same client_message_id + target_device_id = one envelope
CREATE UNIQUE INDEX IF NOT EXISTS idx_de_idempotent
  ON public.device_envelopes(client_message_id, target_device_id);
