-- ============================================================
--  Migration 00005: Create conversation_members table
--  Links users to conversations with role management.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.conversation_members (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role            TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member')),
  joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at         TIMESTAMPTZ,  -- NULL if still active
  UNIQUE(conversation_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_cm_conversation ON public.conversation_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_cm_user ON public.conversation_members(user_id);
CREATE INDEX IF NOT EXISTS idx_cm_active ON public.conversation_members(user_id, conversation_id) WHERE left_at IS NULL;
