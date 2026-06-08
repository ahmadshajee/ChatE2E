-- ============================================================
--  Migration 00007: Create media_objects table
--  Stores encrypted blob METADATA only.
--  Actual encrypted blobs live in Cloudflare R2.
--  Media decryption keys are embedded inside encrypted message
--  envelopes — NOT stored in this table.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.media_objects (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uploader_device_id  UUID NOT NULL REFERENCES public.devices(id) ON DELETE CASCADE,
  conversation_id     UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  storage_key         TEXT NOT NULL,  -- R2 object key (path to encrypted blob)
  content_type_hint   TEXT,           -- e.g. 'image/jpeg' (non-sensitive metadata)
  byte_size           BIGINT NOT NULL DEFAULT 0,
  encryption_iv       TEXT NOT NULL,  -- IV for blob decryption (the key itself is in the envelope, not here)
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_mo_conversation ON public.media_objects(conversation_id);
CREATE INDEX IF NOT EXISTS idx_mo_uploader ON public.media_objects(uploader_device_id);
CREATE INDEX IF NOT EXISTS idx_mo_storage_key ON public.media_objects(storage_key);
