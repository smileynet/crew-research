---
type: specification
title: "Spec: recall import + OKF Retrieval Evaluation"
---

# Spec: recall import + OKF Retrieval Evaluation

**Status:** Ready
**Date:** 2026-07-03 (revised after Codex + subagent review)
**Depends on:** ADR 0007 (recall tool), recall-okf-integration.md

---

## Objective

Add markdown ingestion to recall so it can search across sessions AND knowledge artifacts. Evaluate whether this combined search improves retrieval — establishing the evidence base for all further OKF adoption decisions.

---

## Prerequisites (not in existing code)

1. **`chunk_markdown(text: str) -> list[str]`** in chunker.py — splits markdown on `## ` headings, falls back to CHUNK_SIZE boundaries. The existing `chunk_messages()` expects `(role, text)` tuples and adds quote formatting; markdown files need a different chunking strategy.

2. **Shallow frontmatter parser** — extract `type` and `title` from YAML between `---` fences. Use regex or manual split (NOT PyYAML — avoid new dependency). Must handle: missing frontmatter, `---` inside code fences (skip fenced blocks).

3. **Schema migration path** — `drawers.type` is `TEXT NOT NULL DEFAULT 'fact'`. Imported files without frontmatter get `type='document'`. New nullable column `title TEXT` added via `ALTER TABLE` with `SCHEMA_VERSION = 2` bump.

---

## Deliverables

### 1. `chunk_markdown()` function

```python
def chunk_markdown(text: str) -> list[str]:
    """Chunk markdown by heading boundaries, falling back to size limit."""
```

- Split on `## ` (h2) headings — each section becomes a chunk candidate
- If a section exceeds CHUNK_SIZE, split at paragraph boundaries (double newline)
- Keep frontmatter attached to the first chunk (it contains searchable keywords)
- Return chunks ≥ MIN_CHUNK_SIZE only

### 2. `recall import <path>` command

**Input:** A directory path containing `.md` files.

**Behavior:**
- Recursively find all `.md` files in `<path>` (excluding `index.md`)
- For each file:
  - Parse frontmatter shallowly (extract `type`, `title`)
  - Chunk with `chunk_markdown()`
  - Embed and store in SQLite
- Wing derivation: parent directory name (e.g., `.memory/adr/0007.md` → wing `memory`, room `adr`)
- Source: `import:<relative-path-from-input-dir>`
- Idempotency: skip files where `(source, source_file)` already exists in DB

**Interface:**
```bash
recall import .memory/                    # import all project knowledge
recall import .memory/adr/                # import only ADRs
recall import ~/other-project/.memory/    # import external knowledge
```

**Deferred (add later if eval passes):**
- `--force` flag (delete + reimport)
- `--wing` override
- `--type` filter in search
- Link extraction / graph data

**Schema changes (SCHEMA_VERSION 2):**
```sql
ALTER TABLE drawers ADD COLUMN title TEXT;
-- type remains NOT NULL; imports without frontmatter get type='document'
-- FTS triggers already handle insert; no change needed for new imports
```

### 3. Retrieval evaluation script

`tools/evals/scripts/okf-retrieval-eval.py` — runs the eval programmatically.

**Method:**
- **Condition 1 (baseline):** Fresh temp DB (`RECALL_DB=/tmp/eval-baseline.sqlite3`). Ingest recent sessions only. Run queries. Score.
- **Condition 2 (+memory):** Fresh temp DB. Ingest same sessions + `recall import .memory/`. Run same queries. Score.
- Each condition uses an **isolated database** (no contamination between conditions).

**Queries (8):**

| # | Query | Expected source_file | Category |
|---|-------|---------------------|----------|
| 1 | "What was decided about the recall tool implementation?" | `adr/0007-purpose-built-recall-tool.md` | decision-lookup |
| 2 | "How does the eval harness work?" | `specs/eval-harness.md` | system |
| 3 | "What does progressive loading mean in this project?" | `CONTEXT.md` | term-lookup |
| 4 | "Why did we choose three tiers instead of two?" | `adr/0005-three-tier-deployment.md` | decision-lookup |
| 5 | "How are skills deployed to different tools?" | `specs/tool-adapters.md` | system |
| 6 | "What is the relationship between practices and skills?" | `specs/practice-skill-crosslinks.md` | relationship |
| 7 | "How does multi-turn evaluation work?" | `specs/multi-turn-eval-findings.md` | system |
| 8 | "What customization options exist for per-project skills?" | `adr/0002-per-project-customization.md` | decision-lookup |

**Scoring:**
- `recall@1`: top result `source_file` matches expected
- `recall@3`: expected file in top 3 results (by `source_file`)
- `mrr`: mean reciprocal rank (1/position if found in top 5, else 0)

**Output:** JSON to stdout:
```json
{
  "conditions": {
    "sessions-only": {"recall_at_1": 0.25, "recall_at_3": 0.50, "mrr": 0.35},
    "sessions-plus-memory": {"recall_at_1": 0.75, "recall_at_3": 1.00, "mrr": 0.82}
  },
  "improvement": {"recall_at_3_delta": 0.50},
  "verdict": "PASS"
}
```

**Threshold:** `sessions-plus-memory.recall@3 >= sessions-only.recall@3 + 0.20`

---

## Ordering

```
1. Capture baseline (condition 1) — can run NOW before any code changes
2. Implement chunk_markdown() in chunker.py
3. Implement recall import (cli.py + store.py migration)
4. Run import on .memory/
5. Run eval condition 2 (sessions + memory)
6. Compare. Go/no-go.
```

Step 1 MUST happen before step 3 to establish a clean baseline.

---

## Non-Goals (explicit cuts from review)

- ~~Link extraction~~ — deferred. Zero bearing on retrieval eval. Revisit if eval passes.
- ~~`--type` filter~~ — deferred. Most files have no frontmatter. Test after pilot adds types.
- ~~`--force` reimport~~ — deferred. Simple delete-then-reimport if needed during dev.
- ~~Agent-level eval~~ — separate experiment after retrieval eval passes.
- ~~Batch frontmatter conversion~~ — only after eval proves value.
- ~~doctor.sh enforcement~~ — no consumer yet.
- ~~PyYAML dependency~~ — use shallow regex parser instead.

---

## Acceptance Criteria

1. `recall import .memory/` completes in <10s, indexes all 25 files
2. `recall search "recall tool decision"` returns ADR 0007 in top 3 (after import)
3. `recall import` is idempotent — re-run produces no duplicates (keyed on `source` + `source_file`)
4. Eval script outputs JSON with recall@1, recall@3, MRR per condition
5. `sessions-plus-memory.recall@3 >= sessions-only.recall@3 + 0.20` (quantitative go/no-go)

---

## Estimate

| Task | Effort |
|------|--------|
| Capture baseline (run eval condition 1) | 15 min |
| `chunk_markdown()` implementation | 20 min |
| Schema migration (v1→v2, add title column) | 15 min |
| `recall import` implementation | 45 min |
| Retrieval eval script | 30 min |
| Run eval, analyze, document verdict | 15 min |
| **Total** | ~2.5 hrs |
