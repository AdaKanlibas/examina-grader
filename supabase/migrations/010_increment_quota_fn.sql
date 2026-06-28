-- 010_increment_quota_fn.sql
-- Atomic upsert-increment for user_quota.
-- Called server-side after a successful grading to consume one credit.
-- SECURITY DEFINER runs as the function owner (postgres), bypassing RLS.

CREATE OR REPLACE FUNCTION public.increment_user_quota(p_user_id UUID, p_period TEXT)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.user_quota (user_id, period, count)
  VALUES (p_user_id, p_period, 1)
  ON CONFLICT (user_id, period)
  DO UPDATE SET count = public.user_quota.count + 1;
END;
$$;
