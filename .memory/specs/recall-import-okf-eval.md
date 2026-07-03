# Spec: recall import + OKF Retrieval Evaluation

**Status:** Draft
**Date:** 2026-07-03
**Depends on:** ADR 0007 (recall tool), recall-okf-integration.md

---

## Objective

Add markdown/OKF ingestion to recall so it can search across sessions AND knowledge artifacts. Then evaluate whether this combined search actually improves agent answers — establishing the evidence base for all further OKF adoption decisions.

---

## Deliverables

### 1. `recall import <path>` command

A new CLI subcommand that ingests markdown files into recall's search index.

**Input:** A directory path containing `.md` files (may be OKF-conformant or plain markdown).

**Behavior:**
- Recursively find all `.md` files in `<path>` (excluding `index.md`)
- For each file:
  - Parse YAML frontmatter if present (extract `type`, `title`, `tags`)
  - Chunk the full file content (frontmatter + body) using existing chunker
  - Embed and store in SQLite with metadata
- Wing derivation: directory name (e.g., `.memory/adr/` → wing `memory`, room `adr`)
- Source tagging: `import:<relative-path>` to distinguish from session ingestion
- Idempotent: skip files already imported (by path hash), support `--force` to re-import

**Interface:**
```bash
recall import .memory/                    # import all project knowledge
recall import .memory/adr/                # import only ADRs
recall import ~/other-project/.memory/    # import external knowledge
recall import --force .memory/            # re-import (update changed files)
recall import --wing myproject .memory/   # override wing derivation
```

**Storage schema additions:**
```sql
-- Existing drawers table gains:
-- source = 'import:adr/0007-purpose-built-recall-tool.md'
-- source_file = 'adr/0007-purpose-built-recall-tool.md'
-- New optional metadata (nullable columns or JSON in existing schema):
--   type TEXT      -- from frontmatter type field (NULL if no frontmatter)
--   title TEXT     -- from frontmatter title field
--   link_targets TEXT  -- JSON array of outbound markdown link paths (for future graph)
```

**Constraints:**
- Must work on plain markdown (no frontmatter required)
- Frontmatter, when present, becomes searchable content AND filterable metadata
- File path is the stable identifier (not content hash) — enables update detection
- Total import of `.memory/` (23 files) should complete in <10 seconds

### 2. Type-filtered search (optional, if schema supports it)

Extend `recall search` with `--type` filter:

```bash
recall search "deployment" --type adr        # only ADRs
recall search "eval harness" --type spec     # only specs
```

Falls back to unfiltered if `--type` not provided. Types come from frontmatter; files without frontmatter have `type = NULL` and match all type queries.

### 3. Link extraction (parse only, no graph features yet)

During import, parse markdown content for links matching `[text](path.md)` or `[text](/path.md)`. Store as `link_targets` JSON array on the drawer row.

This is data collection only — no traversal, no ranking boost. The data enables the graph eval in a later phase without requiring re-import.

---

## Retrieval Evaluation

### Eval Definition: `okf-retrieval-baseline`

```yaml
name: okf-retrieval-baseline
type: retrieval
description: "Does importing .memory/ into recall improve agent ability to answer project knowledge questions?"

queries:
  - query: "What was decided about the recall tool implementation?"
    expected: "adr/0007-purpose-built-recall-tool.md"
    category: decision-lookup

  - query: "How does the eval harness work?"
    expected: "specs/eval-harness.md"
    category: system-understanding

  - query: "What does progressive loading mean in this project?"
    expected: "CONTEXT.md"
    category: term-lookup

  - query: "Why did we choose three tiers instead of two?"
    expected: "adr/0005-three-tier-deployment.md"
    category: decision-lookup

  - query: "How are skills deployed to different tools?"
    expected: "specs/tool-adapters.md"
    category: system-understanding

  - query: "What is the relationship between practices and skills?"
    expected: "specs/practice-skill-crosslinks.md"
    category: relationship-query

  - query: "How does multi-turn evaluation work?"
    expected: "specs/multi-turn-eval-findings.md"
    category: system-understanding

  - query: "What customization options exist for per-project skills?"
    expected: "adr/0002-per-project-customization.md"
    category: decision-lookup

conditions:
  - name: sessions-only
    description: "Recall with only session transcripts indexed (current state)"
  - name: sessions-plus-memory
    description: "Recall with sessions AND .memory/ imported (no frontmatter)"
  - name: sessions-plus-memory-typed
    description: "Recall with sessions AND .memory/ imported (with type frontmatter)"

metrics:
  - recall_at_1: top result matches expected file
  - recall_at_3: expected file in top 3 results
  - mrr: mean reciprocal rank across all queries
  - type_precision: (typed condition only) does --type filter eliminate false positives?

threshold:
  sessions-plus-memory should beat sessions-only on recall@3 by ≥20%
```

### Eval Method

Run `recall search` programmatically for each query under each condition:

```bash
# Condition 1: sessions-only (current state, no import)
recall search "$query" --results 3

# Condition 2: sessions + .memory/ (after import, no frontmatter)
recall import .memory/
recall search "$query" --results 3

# Condition 3: sessions + .memory/ with type (after adding type frontmatter)
recall import --force .memory/
recall search "$query" --results 3 --type adr
```

Score each result set against expected file. Compare across conditions.

### Agent-Level Eval (stretch)

If retrieval eval shows improvement, run an agent-level eval:

```yaml
name: okf-agent-context
type: multi-turn
tasks:
  - turns:
      - "What architecture decisions constrain how I can add a new tool adapter?"
    criteria: |
      Agent should identify ADR-0006 (multi-tool deployment) and the tool-adapters spec.
      Score 5: Cites both with correct summaries.
      Score 3: Mentions one or gives vague answer.
      Score 1: Hallucinates or says "I don't know."
```

---

## Non-Goals

- No OKF bundle export (no consumer exists)
- No doctor.sh enforcement (premature)
- No graph traversal features (data collection only — eval first)
- No changes to skill format or skill references/
- No batch-conversion of .memory/ until retrieval eval passes

---

## Acceptance Criteria

1. `recall import .memory/` completes in <10s, indexes all 23 files
2. `recall search "recall tool decision"` returns ADR 0007 in top 3
3. `recall import` is idempotent (re-run produces no duplicates)
4. Link targets are extracted and stored (verifiable via `recall status` or DB query)
5. Retrieval eval runs under all 3 conditions and produces comparable metrics
6. A clear go/no-go decision emerges: does importing .memory/ measurably help?

---

## Estimate

| Task | Effort |
|------|--------|
| `recall import` implementation | 1 hr |
| `--type` filter in search | 20 min |
| Link extraction during import | 20 min |
| Retrieval eval script | 45 min |
| Run eval, analyze results | 30 min |
| Pilot frontmatter (if eval positive) | 15 min |
| Re-run eval with types | 15 min |
| **Total** | ~3.5 hrs |
