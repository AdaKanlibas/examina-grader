# examina-grader  ·  *Examina*

An AI grader for **IB Mathematics** (Analysis & Approaches, SL/HL): a student
submits a worked solution (typed or photographed), it's OCR'd, graded against a
real IB-style **rubric** by an LLM, and low-confidence marks are routed to a human
reviewer. Built around a deterministic, auditable data layer — not a single
prompt.

> **Sanitized showcase.** This repo is a curated subset of the product: the
> **Python service, the Supabase schema/migrations, the content + eval pipeline,
> and the engineering docs**. Removed for publication: the production `.env.local`
> (real keys), all real student submissions and exam PDFs (`content/intake`,
> `testdata`), and an internal reviewer's name. Keys are read from env only; the
> committed `.env.*.example` files are placeholders. See [LICENSE](LICENSE).

## Problem

Marking IB Maths by hand is slow and inconsistent, and a naive "ask the LLM to
grade it" approach hallucinates marks, ignores method marks, and can't be
audited. Grading has to be **rubric-faithful, traceable, and cheap**, with a human
in the loop exactly where the model is unsure.

## Approach

- **Capture → OCR.** A FastAPI service ([`python/app/routes`](python/app/routes))
  exposes `ocr`, `render`, and `verify` endpoints; handwritten work is converted
  to structured text/LaTeX.
- **Retrieve.** Questions, rubrics and topics live in Postgres with **pgvector**
  similarity search ([`supabase/migrations/004_vector_search.sql`](supabase/migrations/004_vector_search.sql))
  so the grader retrieves the right rubric and exemplars.
- **Grade.** An LLM marks against the retrieved rubric and emits per-criterion
  marks + a confidence score.
- **Route.** Clean, high-confidence marks return immediately; low-confidence ones
  ask the student one clarifying question, and only then escalate to a human
  review console.
- **Prove it.** An **eval harness** ([`scripts/run-eval.js`](scripts/run-eval.js))
  scores the grader against a gold set of expert mark decisions.

The data layer is security-conscious: row-level security with a deliberate
**fix migration** ([`007_fix_rls_write_policies.sql`](supabase/migrations/007_fix_rls_write_policies.sql))
that locks question-bank writes to `service_role`, plus per-user quotas
([`009`](supabase/migrations/009_user_quota.sql)/[`010`](supabase/migrations/010_increment_quota_fn.sql)).

## Stack

- **Frontend:** Next.js + TypeScript (config in [`web/`](web/) — Vitest, ESLint,
  strict `tsconfig`).
- **Backend:** Python **FastAPI** ([`python/`](python/)), Dockerfile + Railway config.
- **Data:** **Supabase** / Postgres + **pgvector**, 11 SQL migrations with RLS and
  quota functions.
- **AI:** an LLM for grading; OpenAI `text-embedding-3-small` for retrieval;
  Langfuse for cost/latency tracing.
- **Content/eval:** Node scripts to generate embeddings, load the question bank,
  and run the gold-set evaluation.

## How to run

This is a **showcase subset** (it doesn't run end-to-end from here). Per part:

```bash
# data layer
supabase db reset            # applies supabase/migrations in order

# python service
cd python && pip install -r requirements.txt && uvicorn app.main:app --reload

# content + eval (needs env vars from web/.env.local.example)
node scripts/load-content.js
node scripts/run-eval.js
```

Copy `web/.env.local.example` → `.env.local` and fill in real keys (never commit).

## Result

A rubric-faithful, retrieval-grounded grading pipeline with human-in-the-loop
review, a measurable eval harness, and a security-reviewed data layer. The
engineering reasoning is documented in
[`docs/DECISIONS.md`](docs/DECISIONS.md) and [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

Built by **Ada Kanlıbaş** · Artek Lab · [kanlibastudio.com](https://kanlibastudio.com) · [arteklab.com](https://arteklab.com)
