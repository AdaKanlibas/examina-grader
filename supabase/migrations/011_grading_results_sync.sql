-- 011_grading_results_sync.sql
-- Adds subject, client_id, and user_id to grading_results for cross-device
-- history sync. Also adds RLS SELECT policy so signed-in users can fetch
-- their own history from the browser client.

ALTER TABLE public.grading_results
  ADD COLUMN IF NOT EXISTS subject   TEXT CHECK (subject IN ('AA_SL', 'AA_HL')),
  ADD COLUMN IF NOT EXISTS client_id TEXT,
  ADD COLUMN IF NOT EXISTS user_id   UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS grading_results_user_id_idx ON public.grading_results (user_id);
CREATE INDEX IF NOT EXISTS grading_results_client_id_idx ON public.grading_results (client_id);

-- Authenticated users can read their own results
DROP POLICY IF EXISTS "users_read_own_results" ON public.grading_results;
CREATE POLICY "users_read_own_results"
  ON public.grading_results FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
