-- 007_fix_rls_write_policies.sql
-- SECURITY FIX: Restrict write policies on question bank tables to service_role only.
--
-- BUG: Migration 001 created "service_role_write_*" policies with no role restriction.
-- In Postgres RLS, a policy without TO <role> applies to ALL roles — including
-- 'anon'. Since NEXT_PUBLIC_SUPABASE_ANON_KEY is public, anyone could call:
--
--   DELETE /rest/v1/questions?id=neq.null   (wipe entire question bank)
--
-- FIX: Drop the overly-permissive policies and recreate them scoped TO service_role.
-- service_role already bypasses RLS entirely, so these policies are actually
-- redundant for service_role — they only exist to signal intent. What matters
-- is that anon and authenticated roles can NO LONGER write to these tables.

-- ── topics ────────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "service_role_write_topics" ON public.topics;
CREATE POLICY "service_role_write_topics"
  ON public.topics FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── questions ─────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "service_role_write_questions" ON public.questions;
CREATE POLICY "service_role_write_questions"
  ON public.questions FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── rubrics ───────────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "service_role_write_rubrics" ON public.rubrics;
CREATE POLICY "service_role_write_rubrics"
  ON public.rubrics FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ── benchmark_runs ────────────────────────────────────────────────────────────
-- No write policy existed — add one scoped to service_role for completeness.
DROP POLICY IF EXISTS "service_role_write_benchmarks" ON public.benchmark_runs;
CREATE POLICY "service_role_write_benchmarks"
  ON public.benchmark_runs FOR ALL TO service_role USING (true) WITH CHECK (true);
