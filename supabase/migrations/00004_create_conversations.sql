-- ============================================================
--  Migration 00004: Create conversations table
--  Routing metadata ONLY. No message content, no names,
--  no previews stored server-side.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.conversations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type       TEXT NOT NULL DEFAULT 'direct' CHECK (type IN ('direct', 'group')),
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_conversations_type ON public.conversations(type);

-- Auto-update updated_at
CREATE TRIGGER conversations_updated_at
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();
