-- 008_seed_hl_calculus_base_topics.sql
-- Inserts HL base calculus topics AA-HL-5 through AA-HL-5.8 that were missing
-- from 002_seed_topics.sql.
--
-- 002_seed_topics.sql included all SL base topics AND HL extension topics (5.9+)
-- but skipped HL base topics 5–5.8. Those topics share codes with SL topics
-- but have subject = 'AA_HL' — they must exist for resolveTopicId() in load-content.js
-- to resolve HL question files with topic_code 5.1–5.8 correctly.
--
-- This unblocks 92 AA-HL-5.3 questions (derivatives: product/quotient/chain,
-- implicit diff, L'Hôpital, related rates) from loading.

INSERT INTO public.topics (code, subject, paper, strand, title, sort_order) VALUES
  ('AA-HL-5',   'AA_HL', 'BOTH', 'Calculus', 'Calculus',                               5000),
  ('AA-HL-5.1', 'AA_HL', 'P1',   'Calculus', 'Introduction to differentiation',        5010),
  ('AA-HL-5.2', 'AA_HL', 'P1',   'Calculus', 'Derivatives (power rule)',               5020),
  ('AA-HL-5.3', 'AA_HL', 'BOTH', 'Calculus', 'Derivatives (product/quotient/chain)',   5030),
  ('AA-HL-5.4', 'AA_HL', 'BOTH', 'Calculus', 'Applications of differentiation',        5040),
  ('AA-HL-5.5', 'AA_HL', 'P1',   'Calculus', 'Integration (indefinite)',               5050),
  ('AA-HL-5.6', 'AA_HL', 'P1',   'Calculus', 'Integration (further rules)',            5060),
  ('AA-HL-5.7', 'AA_HL', 'BOTH', 'Calculus', 'Definite integrals & area',              5070),
  ('AA-HL-5.8', 'AA_HL', 'P2',   'Calculus', 'Trapezoidal rule',                       5080)
ON CONFLICT (code) DO NOTHING;
