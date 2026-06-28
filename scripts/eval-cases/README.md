# Eval Test Cases — Format Guide

Each `.json` file in this directory is one test case for the eval harness.
Run with: `node scripts/run-eval.js`

---

## File naming

```
{subject}_{topic}_{difficulty}_{descriptor}.json
```

Examples:
- `AA_SL_5.1_easy_correct.json`
- `AA_HL_5.3_medium_partial.json`
- `AA_SL_5.5_hard_wrong_method.json`

Files starting with `_` are ignored (useful for drafts).

---

## Required fields

```json
{
  "id": "SL-5.1-easy-correct-001",
  "subject": "AA_SL",
  "topic_code": "5.1",
  "gold_marks": {
    "M1": true,
    "A1": true,
    "A2": false
  }
}
```

| Field         | Type     | Description |
|---------------|----------|-------------|
| `id`          | string   | Unique identifier for this case. Used in reports. |
| `subject`     | string   | `"AA_SL"` or `"AA_HL"` |
| `topic_code`  | string   | IB syllabus code: `"5.1"`, `"5.3"`, `"5.5"`, etc. |
| `gold_marks`  | object   | Mark ID → boolean. True = awarded, false = withheld. Must match the mark scheme for the question. |

---

## Image cases (preferred — most accurate eval)

```json
{
  "id": "SL-5.1-easy-correct-001",
  "subject": "AA_SL",
  "topic_code": "5.1",
  "image_path": "../../testdata/SL-5.1-easy-correct.jpg",
  "gold_marks": {
    "M1": true,
    "A1": true,
    "A2": true
  },
  "notes": "Student differentiates correctly, no errors."
}
```

- `image_path`: path to the student's handwritten work, relative to this directory.
- Images go in the `testdata/` directory at the project root.
- **Never commit real student images** — use anonymised or synthetic work only.

---

## Text description cases (quick to create, less realistic)

When you don't have a real image, describe what the student wrote:

```json
{
  "id": "HL-5.3-implicit-partial-001",
  "subject": "AA_HL",
  "topic_code": "5.3",
  "student_description": "Student differentiates x²y + y³ = 5 implicitly. Applies product rule to x²y correctly. Makes sign error in collecting terms: writes 2xy + x²(dy/dx) = 3y²(dy/dx) instead of -3y². Gets incorrect final expression for dy/dx.",
  "gold_marks": {
    "M1": true,
    "A1": false,
    "A2": false
  },
  "notes": "Product rule awarded (M1), but accuracy marks lost due to sign error."
}
```

- `student_description`: plain English description of the student's working.
- This is passed as the `correction` field to the API.
- Less reliable than real images, but useful for edge cases.

---

## Gold mark scheme format

`gold_marks` keys must exactly match the mark IDs in the DB rubric for that question.

To find the correct mark IDs, query the DB:

```sql
select q.stem_text, r.marks
from questions q
join rubrics r on r.question_id = q.id
where q.topic_id in (select id from topics where code like 'AA-SL-5.1%')
limit 5;
```

Or run `node scripts/load-content.js --list` to see all loaded questions.

---

## Example: 3 difficulty levels for one question

For each question in the gold set, the reviewer provides **three student responses**:

### AA_SL_5.1_deriv_basic_wrong.json
```json
{
  "id": "SL-5.1-basic-wrong",
  "subject": "AA_SL",
  "topic_code": "5.1",
  "student_description": "Student writes f'(x) = 6x + 2 but no method shown. No differentiation rule cited.",
  "gold_marks": { "M1": false, "A1": false, "A2": false }
}
```

### AA_SL_5.1_deriv_basic_partial.json
```json
{
  "id": "SL-5.1-basic-partial",
  "subject": "AA_SL",
  "topic_code": "5.1",
  "student_description": "Student correctly uses power rule for 3x². Makes arithmetic error: writes 2x instead of 2 for the derivative of 2x. Shows working.",
  "gold_marks": { "M1": true, "A1": true, "A2": false }
}
```

### AA_SL_5.1_deriv_basic_correct.json
```json
{
  "id": "SL-5.1-basic-correct",
  "subject": "AA_SL",
  "topic_code": "5.1",
  "student_description": "Student correctly differentiates f(x) = 3x² + 2x to get f'(x) = 6x + 2. Method shown. All steps correct.",
  "gold_marks": { "M1": true, "A1": true, "A2": true }
}
```

---

## Target scale

For the 200-question gold set (Phase 5):
- **200 questions** from the DB, spanning all SL and HL topics
- **3 student responses per question** = 600 test cases total
- Split: 60 wrong (all marks withheld), 180 partial, 180 correct (all marks awarded)

For now, **start with 10–20 cases** covering the topics we already have in the DB.
Focus on: AA_SL 5.1, AA_SL 5.3, AA_SL 5.5, AA_HL 5.3 (all well-represented in the DB).
