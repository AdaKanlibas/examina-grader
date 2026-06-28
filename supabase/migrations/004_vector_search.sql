-- ============================================================
-- 004_vector_search.sql
-- 1. Make submissions.user_id nullable (supersedes 003)
-- 2. Create match_questions() RPC for pgvector similarity search
--
-- Run in: Supabase dashboard → SQL Editor
-- ============================================================

-- ── 1. Nullable user_id (was blocking DB persistence) ──────────────────────────
ALTER TABLE public.submissions ALTER COLUMN user_id DROP NOT NULL;

-- ── 2. Semantic similarity search via pgvector ─────────────────────────────────
-- Called from the grading pipeline after extracting question text from the image.
-- Returns the N most similar questions in the bank (cosine distance).

CREATE OR REPLACE FUNCTION public.match_questions(
  query_embedding vector(1536),
  filter_subject   text,
  filter_paper     text    DEFAULT NULL,
  match_count      int     DEFAULT 3
)
RETURNS TABLE (
  id          uuid,
  stem_text   text,
  total_marks int,
  difficulty  int,
  similarity  float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    q.id,
    q.stem_text,
    q.total_marks,
    q.difficulty,
    1 - (q.embedding <=> query_embedding) AS similarity
  FROM public.questions q
  WHERE q.subject = filter_subject
    AND q.embedding IS NOT NULL
    AND (filter_paper IS NULL OR q.paper = filter_paper)
  ORDER BY q.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- Allow the service role to call this function
GRANT EXECUTE ON FUNCTION public.match_questions TO service_role;
