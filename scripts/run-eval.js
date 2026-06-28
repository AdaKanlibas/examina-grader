#!/usr/bin/env node
/**
 * Examina — Eval Harness
 *
 * Runs test cases through the live grading API and computes accuracy metrics
 * against the reviewer's gold-standard mark decisions.
 *
 * Usage:
 *   node scripts/run-eval.js
 *   node scripts/run-eval.js --url https://examina-steel.vercel.app
 *   node scripts/run-eval.js --publish          # writes result to benchmark_runs table
 *   node scripts/run-eval.js --cases ./my-cases # custom case directory
 *   node scripts/run-eval.js --dry-run          # validate cases without calling API
 *
 * Test case format: see scripts/eval-cases/README.md
 */

const fs   = require("fs");
const path = require("path");

// ─── Config ───────────────────────────────────────────────────────────────────

const args        = process.argv.slice(2);
const API_URL     = flag("--url",   "http://localhost:3000");
const CASES_DIR   = flag("--cases", path.join(__dirname, "eval-cases"));
const PUBLISH     = args.includes("--publish");
const DRY_RUN     = args.includes("--dry-run");
const VERBOSE     = args.includes("--verbose");

function flag(name, fallback) {
  const idx = args.indexOf(name);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : fallback;
}

// ─── Env loading ──────────────────────────────────────────────────────────────

const envPath = path.join(__dirname, "..", "web", ".env.local");
const env = {};
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, "utf8").split(/\r?\n/)) {
    const m = line.match(/^([A-Z_][A-Z0-9_]*)=(.+)$/);
    if (m) env[m[1]] = m[2].trim();
  }
}

// ─── Load test cases ──────────────────────────────────────────────────────────

function loadCases() {
  if (!fs.existsSync(CASES_DIR)) {
    console.error(`Cases directory not found: ${CASES_DIR}`);
    console.error("Run with --cases <path> or create scripts/eval-cases/");
    process.exit(1);
  }

  const files = fs.readdirSync(CASES_DIR)
    .filter(f => f.endsWith(".json") && !f.startsWith("_"))
    .sort();

  if (files.length === 0) {
    console.error("No .json test case files found in", CASES_DIR);
    console.error("See scripts/eval-cases/README.md for the format.");
    process.exit(1);
  }

  const cases = [];
  for (const file of files) {
    const raw = fs.readFileSync(path.join(CASES_DIR, file), "utf8");
    let tc;
    try {
      tc = JSON.parse(raw);
    } catch (e) {
      console.error(`  ✗ ${file}: invalid JSON — ${e.message}`);
      continue;
    }

    // Validate required fields
    const required = ["id", "subject", "gold_marks"];
    const missing  = required.filter(k => !(k in tc));
    if (missing.length > 0) {
      console.error(`  ✗ ${file}: missing fields: ${missing.join(", ")}`);
      continue;
    }
    if (!tc.image_path && !tc.student_description) {
      console.error(`  ✗ ${file}: must have either 'image_path' or 'student_description'`);
      continue;
    }

    cases.push({ ...tc, _file: file });
  }

  return cases;
}

// ─── Encode image ─────────────────────────────────────────────────────────────

function encodeImage(imagePath) {
  const absPath = path.isAbsolute(imagePath)
    ? imagePath
    : path.resolve(CASES_DIR, imagePath);

  if (!fs.existsSync(absPath)) {
    throw new Error(`Image not found: ${absPath}`);
  }

  const ext = path.extname(absPath).toLowerCase();
  const mimeMap = { ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png", ".webp": "image/webp", ".heic": "image/heic" };
  const mime = mimeMap[ext];
  if (!mime) throw new Error(`Unsupported image extension: ${ext}`);

  return {
    image_base64: fs.readFileSync(absPath).toString("base64"),
    mime_type: mime,
  };
}

// ─── Call grading API ─────────────────────────────────────────────────────────

async function gradeCase(tc) {
  let imagePayload;

  if (tc.image_path) {
    imagePayload = encodeImage(tc.image_path);
  } else {
    // Text-only mode: use a 1x1 white pixel PNG + correction field as context.
    // This tests the rubric retrieval + grading logic with a text description.
    const WHITE_PIXEL = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwADhQGAWjR9awAAAABJRU5ErkJggg==";
    imagePayload = { image_base64: WHITE_PIXEL, mime_type: "image/png" };
  }

  const body = {
    ...imagePayload,
    subject:    tc.subject,
    correction: tc.student_description ?? tc.correction ?? undefined,
  };

  const res = await fetch(`${API_URL}/api/grade`, {
    method:  "POST",
    headers: { "Content-Type": "application/json" },
    body:    JSON.stringify(body),
  });

  if (!res.ok || !res.body) {
    throw new Error(`HTTP ${res.status} from API`);
  }

  // Parse SSE stream
  const reader  = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const chunks = buffer.split("\n\n");
    buffer = chunks.pop() ?? "";

    for (const chunk of chunks) {
      if (!chunk.startsWith("data: ")) continue;
      let event;
      try { event = JSON.parse(chunk.slice(6)); } catch { continue; }

      if (event.type === "result") return event.result;
      if (event.type === "error") throw new Error(event.error ?? "Grading API error");
    }
  }

  throw new Error("Stream ended without result");
}

// ─── Compare marks ────────────────────────────────────────────────────────────

/**
 * Compare AI marks against gold marks.
 *
 * gold_marks format:  { "M1": true, "A1": false, "A2": true }
 * AI result.marks:    [{ mark_id: "M1", awarded: true, ... }]
 *
 * Returns: { agreed, false_positives, false_negatives, total, per_mark }
 */
function compareMarks(gold, aiResult) {
  const aiMap = {};
  for (const m of aiResult.marks) {
    aiMap[m.mark_id] = m.awarded;
  }

  let agreed = 0, fp = 0, fn = 0, total = 0;
  const per_mark = {};

  for (const [markId, goldAwarded] of Object.entries(gold)) {
    total++;
    const aiAwarded = aiMap[markId] ?? false;

    if (aiAwarded === goldAwarded) {
      agreed++;
      per_mark[markId] = "agree";
    } else if (aiAwarded && !goldAwarded) {
      fp++;
      per_mark[markId] = "false_positive";
    } else {
      fn++;
      per_mark[markId] = "false_negative";
    }
  }

  return { agreed, false_positives: fp, false_negatives: fn, total, per_mark };
}

// ─── Aggregate metrics ────────────────────────────────────────────────────────

function computeMetrics(results) {
  let totalMarks = 0, totalAgreed = 0, totalFP = 0, totalFN = 0;
  const topicMap = {};  // topic → { total_marks, agreed, false_positives, false_negatives }

  for (const r of results) {
    totalMarks  += r.comparison.total;
    totalAgreed += r.comparison.agreed;
    totalFP     += r.comparison.false_positives;
    totalFN     += r.comparison.false_negatives;

    const topic = `${r.subject}-${r.topic ?? "unknown"}`;
    if (!topicMap[topic]) topicMap[topic] = { total_marks: 0, agreed: 0, false_positives: 0, false_negatives: 0 };
    topicMap[topic].total_marks       += r.comparison.total;
    topicMap[topic].agreed            += r.comparison.agreed;
    topicMap[topic].false_positives   += r.comparison.false_positives;
    topicMap[topic].false_negatives   += r.comparison.false_negatives;
  }

  const per_topic_breakdown = {};
  for (const [topic, data] of Object.entries(topicMap)) {
    per_topic_breakdown[topic] = {
      ...data,
      agreement_rate: data.total_marks > 0 ? data.agreed / data.total_marks : 0,
    };
  }

  return {
    total_questions:     results.length,
    total_marks:         totalMarks,
    mark_agreement_rate: totalMarks > 0 ? totalAgreed / totalMarks : 0,
    false_positive_rate: totalMarks > 0 ? totalFP     / totalMarks : 0,
    false_negative_rate: totalMarks > 0 ? totalFN     / totalMarks : 0,
    per_topic_breakdown,
  };
}

// ─── Write to DB ──────────────────────────────────────────────────────────────

async function publishToDB(metrics, graderVersion) {
  const { createClient } = require("@supabase/supabase-js");
  const sb = createClient(env.NEXT_PUBLIC_SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data, error } = await sb.from("benchmark_runs").insert({
    run_date:            new Date().toISOString().split("T")[0],
    grader_version:      graderVersion,
    total_questions:     metrics.total_questions,
    mark_agreement_rate: metrics.mark_agreement_rate.toFixed(4),
    false_positive_rate: metrics.false_positive_rate.toFixed(4),
    false_negative_rate: metrics.false_negative_rate.toFixed(4),
    per_topic_breakdown: metrics.per_topic_breakdown,
    is_published:        metrics.mark_agreement_rate >= 0.85,
  }).select("id, is_published").single();

  if (error) throw new Error(`DB insert failed: ${error.message}`);
  return data;
}

// ─── Report ───────────────────────────────────────────────────────────────────

function printReport(metrics, results) {
  const pct = n => `${(n * 100).toFixed(1)}%`;
  const TARGET_AGREEMENT = 0.85;

  console.log("\n" + "─".repeat(60));
  console.log("  EXAMINA EVAL REPORT");
  console.log("─".repeat(60));
  console.log(`  Questions tested:   ${metrics.total_questions}`);
  console.log(`  Marks tested:       ${metrics.total_marks}`);
  console.log(`  Agreement rate:     ${pct(metrics.mark_agreement_rate)}  (target ≥ 85%)  ${metrics.mark_agreement_rate >= TARGET_AGREEMENT ? "✅" : "❌"}`);
  console.log(`  False positive:     ${pct(metrics.false_positive_rate)}  (target < 5%)   ${metrics.false_positive_rate < 0.05 ? "✅" : "❌"}`);
  console.log(`  False negative:     ${pct(metrics.false_negative_rate)}  (target < 10%)  ${metrics.false_negative_rate < 0.10 ? "✅" : "❌"}`);
  console.log("─".repeat(60));

  if (Object.keys(metrics.per_topic_breakdown).length > 0) {
    console.log("  Per-topic breakdown:");
    for (const [topic, data] of Object.entries(metrics.per_topic_breakdown)) {
      const bar = "█".repeat(Math.round(data.agreement_rate * 20)).padEnd(20);
      console.log(`    ${topic.padEnd(18)} ${bar} ${pct(data.agreement_rate)}`);
    }
    console.log("─".repeat(60));
  }

  if (VERBOSE) {
    console.log("\n  Per-case breakdown:");
    for (const r of results) {
      const icon = r.error ? "✗" : r.comparison.agreed === r.comparison.total ? "✓" : "~";
      const mark = r.error ? r.error : `${r.comparison.agreed}/${r.comparison.total} agreed`;
      console.log(`    ${icon} ${r.id.padEnd(30)} ${mark}`);
    }
    console.log("─".repeat(60));
  }

  console.log();
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\nExamina Eval Harness");
  console.log(`API: ${API_URL}`);
  console.log(`Cases: ${CASES_DIR}`);
  if (DRY_RUN)  console.log("Mode: DRY RUN (no API calls)");
  if (PUBLISH)  console.log("Mode: will publish to DB if agreement ≥ 85%");
  console.log();

  const cases = loadCases();
  console.log(`Loaded ${cases.length} test case(s)`);

  if (DRY_RUN) {
    console.log("Dry run — all cases valid. Exiting.");
    return;
  }

  const results = [];
  let passed = 0, failed = 0;
  let graderVersion = "unknown";

  for (let i = 0; i < cases.length; i++) {
    const tc = cases[i];
    process.stdout.write(`  [${String(i + 1).padStart(3)}/${cases.length}] ${tc.id} … `);

    try {
      const start  = Date.now();
      const result = await gradeCase(tc);
      const ms     = Date.now() - start;

      graderVersion = result.grader_version ?? graderVersion;
      const comparison = compareMarks(tc.gold_marks, result);
      results.push({ id: tc.id, subject: tc.subject, topic: tc.topic_code, comparison, result });

      const icon = comparison.agreed === comparison.total ? "✓" : "~";
      console.log(`${icon}  ${comparison.agreed}/${comparison.total} agreed  (${ms}ms)`);
      passed++;
    } catch (e) {
      console.log(`✗  ERROR: ${e.message}`);
      results.push({ id: tc.id, subject: tc.subject, topic: tc.topic_code, comparison: { agreed: 0, false_positives: 0, false_negatives: 0, total: Object.keys(tc.gold_marks).length }, error: e.message });
      failed++;
    }
  }

  const metrics = computeMetrics(results);
  printReport(metrics, results);

  if (PUBLISH) {
    console.log("Publishing to benchmark_runs table…");
    try {
      const row = await publishToDB(metrics, graderVersion);
      if (row.is_published) {
        console.log(`✅ Published (id: ${row.id}) — agreement ≥ 85%, visible at /benchmark`);
      } else {
        console.log(`📝 Saved (id: ${row.id}) — not published yet (agreement < 85%)`);
      }
    } catch (e) {
      console.error("DB publish failed:", e.message);
    }
  }

  // Exit with non-zero code if targets not met — lets CI fail the check
  const ok = metrics.mark_agreement_rate >= 0.85
    && metrics.false_positive_rate < 0.05
    && metrics.false_negative_rate < 0.10;

  process.exit(ok ? 0 : 1);
}

main().catch(e => { console.error("Fatal:", e.message); process.exit(1); });
