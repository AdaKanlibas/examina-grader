# Examina — Architectural Decision Records (ADR)

All non-obvious technical and product decisions are logged here in chronological order.
Format: context → decision → trade-off accepted.

---

## ADR-001 — SymPy veto on A-marks is non-negotiable
**Date:** 2026-05-30  
**Context:** LLMs are unreliable on arithmetic and algebraic simplification under production conditions. A student who gets a correct answer marked wrong will leave and tell r/IBO.  
**Decision:** SymPy independently verifies every A-mark (accuracy mark) before the result is returned. If SymPy says the student's answer is wrong, the A-mark is withheld regardless of LLM confidence.  
**Trade-off:** Adds ~100ms latency per A-mark. Worth it unconditionally.

---

## ADR-002 — Prompt caching on mark scheme corpus
**Date:** 2026-05-30  
**Context:** Every grading call for the same topic sends the same mark scheme in context. Without caching, this is paid for on every call.  
**Decision:** Use Anthropic prompt caching. The mark scheme corpus is the cache prefix. At 80% cache hit rate, input token cost drops from $3/M to $0.30/M.  
**Trade-off:** Cache TTL is 5 minutes; cold starts pay full price. Acceptable.

---

## ADR-003 — Dual-grader ensemble + Opus tiebreaker
**Date:** 2026-05-30  
**Context:** Single-pass grading on ambiguous student work (unusual method, messy handwriting) produces low-confidence results we can't trust.  
**Decision:** When any mark confidence < 0.60, run two Sonnet 4.6 passes at different temperatures. On disagreement, Opus 4.7 adjudicates with both results in context.  
**Trade-off:** ~10% of submissions hit dual-grader; ~5% hit Opus. Cost impact is modelled in ROADMAP.md and is acceptable at all scales.

---

## ADR-004 — Student clarification before human escalation
**Date:** 2026-05-30  
**Context:** the reviewer's time is finite. Many low-confidence marks result from ambiguous student writing, not genuinely hard marking calls.  
**Decision:** Before routing to the human review queue, the AI asks the student one targeted clarifying question. Student response is fed back into the grading pass. Only if confidence is still < 0.55 after clarification does the reviewer see it.  
**Trade-off:** Adds one round-trip delay for the student. Better than waiting 24h for human review.

---

## ADR-005 — Fixed questions in Phase 3, parameterized in Phase 4
**Date:** 2026-05-30  
**Context:** Parameterized questions (one template → many numerical variants) are more durable but require more schema complexity and authoring tooling.  
**Decision:** Phase 3 launches with 10 fixed seed questions. The schema includes `template_id` and `parameters` columns from day one (null for fixed questions). Phase 4 activates parameterization.  
**Trade-off:** Phase 3 questions can be shared between students. Acceptable for a 10-question dev phase.

---

## ADR-006 — Supabase EU region only, no cross-region replication at MVP
**Date:** 2026-05-30  
**Context:** Student data (uploads, grading results) must not leave the EU under GDPR. Company may be registered in Turkey; Turkish data law (KVKK) has similar residency requirements.  
**Decision:** Single Supabase project in EU (Frankfurt) region. No replication to other regions in v1.  
**Trade-off:** Higher latency for users outside Europe (Turkey, Asia). Acceptable for MVP user base. Revisit at 50K+ users.

---

## ADR-007 — pgvector in Supabase, not a separate vector database
**Date:** 2026-05-30  
**Context:** Question bank similarity search requires vector embeddings. Options: Pinecone, Weaviate, or pgvector extension in the existing Supabase Postgres.  
**Decision:** pgvector. At MVP scale (<10K questions), query latency is well within bounds. Fewer services to operate and monitor.  
**Trade-off:** pgvector IVFFlat index is less accurate than HNSW at very large scale. Migrate to HNSW or dedicated vector DB if question bank exceeds 100K entries.

---

## ADR-008 — Manim + ElevenLabs for AI video explanation
**Date:** 2026-05-30  
**Context:** AI video walkthroughs are a launch-critical differentiator. Options: static screen recordings, AI avatar services (HeyGen), or programmatic generation.  
**Decision:** Manim (headless, Python service on Railway) for math animation + ElevenLabs TTS for voiceover. Output cached in Supabase storage by (question_id, language).  
**Trade-off:** First generation per question takes 30–90s. Subsequent requests are instant (cache hit). Cache warming strategy: pre-generate videos for the 200-question benchmark set before launch.

---
