/**
 * generate-embeddings.js
 * Generates OpenAI text-embedding-3-small vectors for all questions
 * in the Supabase questions table that still have NULL embeddings.
 *
 * Idempotent — safe to run multiple times. Only processes NULLs.
 * Cost: ~$0.001 for 122 questions (essentially free).
 *
 * Run from project root:
 *   npm run generate-embeddings   (from web/ directory)
 * Or directly:
 *   node scripts/generate-embeddings.js
 */

const fs   = require("fs");
const path = require("path");

// ── Load env from web/.env.local ──────────────────────────────────────────────

function loadEnv() {
  const envPath = path.join(__dirname, "../web/.env.local");
  const raw = fs.readFileSync(envPath, "utf8");
  const env = {};
  for (const line of raw.split("\n")) {
    const trimmed = line.trim();
    if (trimmed.startsWith("#") || !trimmed.includes("=")) continue;
    const eqIdx = trimmed.indexOf("=");
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim();
    if (key) env[key] = val;
  }
  return env;
}

const fileEnv = loadEnv();
const BASE     = (process.env.NEXT_PUBLIC_SUPABASE_URL     || fileEnv.NEXT_PUBLIC_SUPABASE_URL     || "").replace(/\/$/, "");
const SB_KEY   =  process.env.SUPABASE_SERVICE_ROLE_KEY    || fileEnv.SUPABASE_SERVICE_ROLE_KEY;
const OAI_KEY  =  process.env.OPENAI_API_KEY               || fileEnv.OPENAI_API_KEY;

if (!BASE || !SB_KEY || !OAI_KEY) {
  console.error("❌  Missing required env vars:");
  if (!BASE)    console.error("   NEXT_PUBLIC_SUPABASE_URL");
  if (!SB_KEY)  console.error("   SUPABASE_SERVICE_ROLE_KEY");
  if (!OAI_KEY) console.error("   OPENAI_API_KEY");
  process.exit(1);
}

// ── Config ────────────────────────────────────────────────────────────────────

const MODEL      = "text-embedding-3-small";
const DIMENSIONS = 1536;  // must match questions.embedding vector(1536)
const BATCH_SIZE = 20;    // OpenAI embeddings API accepts up to 2048 inputs
const DELAY_MS   = 150;   // rate-limit breathing room

// ── Helpers ───────────────────────────────────────────────────────────────────

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function fetchQuestionsNeedingEmbedding() {
  const url = `${BASE}/rest/v1/questions?select=id,stem_text&embedding=is.null&limit=2000`;
  const res = await fetch(url, {
    headers: {
      apikey:        SB_KEY,
      Authorization: `Bearer ${SB_KEY}`,
    },
  });
  if (!res.ok) throw new Error(`Supabase fetch failed: ${await res.text()}`);
  return res.json();
}

async function getEmbeddings(texts) {
  const res = await fetch("https://api.openai.com/v1/embeddings", {
    method: "POST",
    headers: {
      Authorization:  `Bearer ${OAI_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ model: MODEL, input: texts, dimensions: DIMENSIONS }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`OpenAI error: ${err}`);
  }
  const data = await res.json();
  // data.data is ordered to match input array
  return data.data.map(d => d.embedding);
}

async function storeEmbedding(id, embedding) {
  // pgvector expects the vector as a string "[x1,x2,...]"
  const vectorStr = `[${embedding.join(",")}]`;
  const res = await fetch(`${BASE}/rest/v1/questions?id=eq.${id}`, {
    method: "PATCH",
    headers: {
      apikey:          SB_KEY,
      Authorization:   `Bearer ${SB_KEY}`,
      "Content-Type":  "application/json",
      Prefer:          "return=minimal",
    },
    body: JSON.stringify({ embedding: vectorStr }),
  });
  if (!res.ok) throw new Error(`Supabase PATCH failed for ${id}: ${await res.text()}`);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  console.log("🔍  Fetching questions with NULL embeddings…");
  const questions = await fetchQuestionsNeedingEmbedding();

  if (questions.length === 0) {
    console.log("✅  All questions already have embeddings — nothing to do.");
    return;
  }

  const total = questions.length;
  console.log(`📝  ${total} question${total === 1 ? "" : "s"} to embed (model: ${MODEL})\n`);

  let done = 0;

  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    const batch = questions.slice(i, i + BATCH_SIZE);
    const texts = batch.map(q => q.stem_text);

    const batchNum  = Math.floor(i / BATCH_SIZE) + 1;
    const batchTotal = Math.ceil(questions.length / BATCH_SIZE);
    process.stdout.write(`  Batch ${batchNum}/${batchTotal} — embedding ${batch.length} questions… `);

    let embeddings;
    try {
      embeddings = await getEmbeddings(texts);
    } catch (err) {
      console.error(`\n❌  OpenAI call failed: ${err.message}`);
      process.exit(1);
    }

    for (let j = 0; j < batch.length; j++) {
      try {
        await storeEmbedding(batch[j].id, embeddings[j]);
        done++;
      } catch (err) {
        console.error(`\n⚠️   Failed to store embedding for ${batch[j].id}: ${err.message} (skipping)`);
      }
    }

    console.log(`✓  (${done}/${total} total)`);

    if (i + BATCH_SIZE < questions.length) await sleep(DELAY_MS);
  }

  console.log(`\n✅  Done! ${done}/${total} embeddings stored.\n`);
  console.log("   Vector search is now active — the grading API will automatically");
  console.log("   use semantic matching for the next grading request.\n");
}

main().catch(err => {
  console.error("\n❌  Fatal error:", err.message);
  process.exit(1);
});
