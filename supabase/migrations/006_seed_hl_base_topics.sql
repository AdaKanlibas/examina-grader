-- 006_seed_hl_base_topics.sql
-- Inserts the 3 HL base topic rows that were missing from 002_seed_topics.sql.
-- These were manually inserted via Supabase SQL Editor on 2026-06-10 to unblock
-- 5 AA-HL questions (1.2 arithmetic sequences, 1.6 proof) from loading.
--
-- 002_seed_topics.sql included all SL base topics AND HL extension topics (1.10+)
-- but skipped HL base topics 1.1–1.9. Those topics share codes with SL topics
-- but have subject = 'AA_HL' — they must exist for resolveTopicId() in load-content.js
-- to resolve HL question files correctly.

INSERT INTO public.topics (code, subject, paper, strand, title, sort_order) VALUES
  ('AA-HL-1',   'AA_HL', 'BOTH', 'Algebra', 'Number and Algebra',                 1000),
  ('AA-HL-1.2', 'AA_HL', 'P1',   'Algebra', 'Arithmetic sequences & series',      1002),
  ('AA-HL-1.6', 'AA_HL', 'P1',   'Algebra', 'Proof by deduction & contradiction', 1006)
ON CONFLICT (code) DO NOTHING;
