-- 009_user_quota.sql
-- Tracks monthly grading usage per authenticated user.
-- Used by rate limiting middleware (Phase 4.2).
-- period format: 'YYYY-MM' (e.g. '2026-06')

CREATE TABLE IF NOT EXISTS public.user_quota (
  user_id UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period  TEXT        NOT NULL,
  count   INTEGER     NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, period)
);

ALTER TABLE public.user_quota ENABLE ROW LEVEL SECURITY;

-- Users can only read their own quota
CREATE POLICY "users_read_own_quota"
  ON public.user_quota FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Only service_role can write quota rows (incremented server-side)
CREATE POLICY "service_role_write_quota"
  ON public.user_quota FOR ALL
  TO service_role
  USING (true) WITH CHECK (true);
