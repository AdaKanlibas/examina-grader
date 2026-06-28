-- ─── Cleanup expired submission images via pg_cron ────────────────────────────
-- Runs every hour. Deletes storage objects for submissions past their 48h TTL.
-- The marks + grading_results rows are NEVER deleted — only the raw image file.
-- Supabase stores file metadata in storage.objects; deleting from that table
-- removes the actual file from the storage bucket.

CREATE OR REPLACE FUNCTION public.cleanup_expired_submissions()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT id, storage_path
    FROM public.submissions
    WHERE storage_ttl < now()
      AND storage_path IS NOT NULL
      AND storage_path <> ''
  LOOP
    -- Remove from Supabase Storage (deletes the actual file)
    DELETE FROM storage.objects
    WHERE bucket_id = 'submissions'
      AND name = rec.storage_path;

    -- Clear path so we never try to delete again
    UPDATE public.submissions
    SET storage_path = ''
    WHERE id = rec.id;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_expired_submissions() TO postgres;

-- Schedule: runs at the top of every hour
SELECT cron.schedule(
  'cleanup-expired-submissions',
  '0 * * * *',
  'SELECT public.cleanup_expired_submissions()'
);
