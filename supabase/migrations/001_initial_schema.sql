-- ============================================================
-- Examina — Full schema migration
-- Run in Supabase SQL Editor: dashboard.supabase.com → SQL Editor
-- ============================================================

-- EXTENSIONS
create extension if not exists "vector";
create extension if not exists "pg_cron";
create extension if not exists "uuid-ossp";

-- ============================================================
-- PROFILES (extends Supabase auth.users)
-- ============================================================
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  display_name    text,
  email           text unique not null,
  age_verified    boolean not null default false,
  tier            text not null default 'free'
                  check (tier in ('free','pro','tutor')),
  preferred_lang  text not null default 'tr',
  timezone        text not null default 'Europe/Amsterdam',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================
create table if not exists public.subscriptions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null references public.profiles(id) on delete cascade,
  stripe_customer_id  text unique,
  stripe_sub_id       text unique,
  status              text not null default 'inactive'
                      check (status in ('active','inactive','past_due','canceled')),
  plan                text,
  currency            text not null default 'eur',
  current_period_end  timestamptz,
  cancel_at_period_end boolean not null default false,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

-- ============================================================
-- IB SYLLABUS TOPICS
-- ============================================================
create table if not exists public.topics (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  subject     text not null check (subject in ('AA_SL','AA_HL')),
  paper       text not null check (paper in ('P1','P2','BOTH')),
  strand      text not null,
  title       text not null,
  parent_id   uuid references public.topics(id),
  sort_order  int not null default 0
);

-- ============================================================
-- QUESTION BANK
-- ============================================================
create table if not exists public.questions (
  id              uuid primary key default gen_random_uuid(),
  topic_id        uuid not null references public.topics(id),
  subject         text not null check (subject in ('AA_SL','AA_HL')),
  paper           text not null check (paper in ('P1','P2')),
  difficulty      int not null check (difficulty between 1 and 5),
  total_marks     int not null,
  stem_text       text not null,
  stem_image_url  text,
  template_id     uuid,
  parameters      jsonb,
  embedding       vector(1536),
  validated_by    text,
  validated_at    timestamptz,
  is_benchmark    boolean not null default false,
  created_at      timestamptz not null default now()
);

-- ============================================================
-- RUBRICS
-- ============================================================
create table if not exists public.rubrics (
  id          uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  version     int not null default 1,
  marks       jsonb not null,
  notes       text,
  authored_by text not null,
  created_at  timestamptz not null default now(),
  unique (question_id, version)
);

-- ============================================================
-- SUBMISSIONS
-- ============================================================
create table if not exists public.submissions (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.profiles(id) on delete cascade,
  question_id     uuid references public.questions(id),
  subject         text check (subject in ('AA_SL','AA_HL')),
  paper           text check (paper in ('P1','P2')),
  input_type      text not null check (input_type in ('image','pdf','latex','text')),
  storage_path    text not null default '',
  storage_ttl     timestamptz not null default (now() + interval '48 hours'),
  ocr_used        boolean not null default false,
  ocr_latex       text,
  status          text not null default 'pending'
                  check (status in ('pending','grading','graded','failed')),
  created_at      timestamptz not null default now()
);

-- ============================================================
-- GRADING RESULTS
-- ============================================================
create table if not exists public.grading_results (
  id                  uuid primary key default gen_random_uuid(),
  submission_id       uuid not null references public.submissions(id) on delete cascade,
  rubric_id           uuid references public.rubrics(id),
  total_available     int not null,
  total_awarded       int not null,
  overall_confidence  numeric(4,3) not null check (overall_confidence between 0 and 1),
  grader_model        text not null,
  grader_version      text not null,
  dual_grader_used    boolean not null default false,
  tiebreaker_used     boolean not null default false,
  sympy_verified      boolean not null default false,
  langfuse_trace_id   text,
  raw_llm_output      jsonb,
  -- Phase 3+ extra fields for inferred-mode results
  rubric_source       text,
  question_identified text,
  subject_area        text,
  examiner_note       text,
  inferred_mark_scheme jsonb,
  created_at          timestamptz not null default now()
);

-- ============================================================
-- MARKS (individual decisions within a result)
-- ============================================================
create table if not exists public.marks (
  id              uuid primary key default gen_random_uuid(),
  result_id       uuid not null references public.grading_results(id) on delete cascade,
  mark_id         text not null,
  mark_type       text not null check (mark_type in ('M','A','R')),
  awarded         boolean not null,
  confidence      numeric(4,3) not null check (confidence between 0 and 1),
  rationale       text not null,
  student_excerpt text,
  follow_through  boolean not null default false,
  bod_applied     boolean not null default false,
  sympy_checked   boolean not null default false,
  sympy_result    text check (sympy_result in ('agree','disagree','not_applicable')),
  sort_order      int not null default 0
);

-- ============================================================
-- HUMAN REVIEW QUEUE
-- ============================================================
create table if not exists public.review_requests (
  id              uuid primary key default gen_random_uuid(),
  result_id       uuid not null references public.grading_results(id) on delete cascade,
  mark_id         uuid references public.marks(id),
  trigger         text not null
                  check (trigger in ('student_request','low_confidence','ai_clarification_failed')),
  clarification_question  text,
  student_clarification   text,
  status          text not null default 'pending'
                  check (status in ('pending','assigned','resolved')),
  assigned_to     text,
  reviewer_verdict  jsonb,
  reviewer_notes  text,
  resolved_at     timestamptz,
  created_at      timestamptz not null default now()
);

-- ============================================================
-- PRACTICE TESTS
-- ============================================================
create table if not exists public.practice_tests (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  topic_ids   uuid[] not null,
  subject     text not null check (subject in ('AA_SL','AA_HL')),
  paper       text not null check (paper in ('P1','P2')),
  questions   jsonb not null,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- VIDEO CACHE
-- ============================================================
create table if not exists public.video_cache (
  id              uuid primary key default gen_random_uuid(),
  question_id     uuid not null references public.questions(id) on delete cascade,
  language        text not null default 'tr' check (language in ('tr','en')),
  storage_path    text not null,
  duration_secs   int,
  generation_cost numeric(8,4),
  created_at      timestamptz not null default now(),
  unique (question_id, language)
);

-- ============================================================
-- BENCHMARK RUNS
-- ============================================================
create table if not exists public.benchmark_runs (
  id                  uuid primary key default gen_random_uuid(),
  run_date            date not null,
  grader_version      text not null,
  total_questions     int not null,
  mark_agreement_rate numeric(5,4) not null,
  false_positive_rate numeric(5,4) not null,
  false_negative_rate numeric(5,4) not null,
  per_topic_breakdown jsonb,
  is_published        boolean not null default false,
  created_at          timestamptz not null default now()
);

-- ============================================================
-- USAGE COUNTERS (free tier rate limiting)
-- ============================================================
create table if not exists public.usage_counters (
  user_id             uuid primary key references public.profiles(id) on delete cascade,
  graded_this_month   int not null default 0,
  practice_today      int not null default 0,
  month_reset_at      date not null default date_trunc('month', now())::date,
  day_reset_at        date not null default current_date
);

-- ============================================================
-- ROW-LEVEL SECURITY
-- ============================================================
alter table public.profiles          enable row level security;
alter table public.subscriptions     enable row level security;
alter table public.submissions       enable row level security;
alter table public.grading_results   enable row level security;
alter table public.marks             enable row level security;
alter table public.review_requests   enable row level security;
alter table public.practice_tests    enable row level security;
alter table public.video_cache       enable row level security;
alter table public.usage_counters    enable row level security;

-- Topics/questions/rubrics: public read, service-role write
alter table public.topics            enable row level security;
alter table public.questions         enable row level security;
alter table public.rubrics           enable row level security;
alter table public.benchmark_runs    enable row level security;

create policy "users_own_profile"       on public.profiles       for all using (auth.uid() = id);
create policy "users_own_subscriptions" on public.subscriptions  for all using (auth.uid() = user_id);
create policy "users_own_submissions"   on public.submissions    for all using (auth.uid() = user_id);
create policy "users_own_results"       on public.grading_results
  for select using (
    exists (select 1 from public.submissions s where s.id = submission_id and s.user_id = auth.uid())
  );
create policy "users_own_marks"         on public.marks
  for select using (
    exists (
      select 1 from public.grading_results r
      join public.submissions s on s.id = r.submission_id
      where r.id = result_id and s.user_id = auth.uid()
    )
  );
create policy "users_own_practice"      on public.practice_tests for all using (auth.uid() = user_id);
create policy "users_own_usage"         on public.usage_counters  for all using (auth.uid() = user_id);

create policy "public_read_topics"      on public.topics       for select using (true);
create policy "public_read_questions"   on public.questions    for select using (true);
create policy "public_read_rubrics"     on public.rubrics      for select using (true);
create policy "public_read_video_cache" on public.video_cache  for select using (true);
create policy "public_read_benchmarks"  on public.benchmark_runs
  for select using (is_published = true);

-- Service role can write to content tables (no user auth needed for content loader)
create policy "service_role_write_topics"    on public.topics    for all using (true) with check (true);
create policy "service_role_write_questions" on public.questions for all using (true) with check (true);
create policy "service_role_write_rubrics"   on public.rubrics   for all using (true) with check (true);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists questions_embedding_idx
  on public.questions using ivfflat (embedding vector_cosine_ops) with (lists = 100);
create index if not exists submissions_user_idx
  on public.submissions (user_id, created_at desc);
create index if not exists marks_result_idx
  on public.marks (result_id, sort_order);
create index if not exists review_requests_status_idx
  on public.review_requests (status, created_at);
create index if not exists grading_results_submission_idx
  on public.grading_results (submission_id);
create index if not exists topics_code_idx
  on public.topics (code);
create index if not exists questions_topic_idx
  on public.questions (topic_id, subject, paper);
