-- Phase 3 migration: make submissions.user_id nullable
-- Run in Supabase SQL Editor
-- Needed because Phase 2/3 grading has no auth yet

ALTER TABLE public.submissions
  ALTER COLUMN user_id DROP NOT NULL;

-- Confirm
SELECT column_name, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'submissions'
  AND column_name = 'user_id';