# Recall Integration Proposal (v2)

## Intent

Give agents persistent cross-session memory via `recall` — a purpose-built CLI tool that provides hybrid semantic + keyword search over ingested conversation history, with agent write-back for decisions and learnings.

**Approach:** CLI + skill (Beads pattern). No MCP server. Agents shell out to `recall search`, `recall add`, `recall prime`. Works with any tool that has shell access.

## Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Skill + eager-context, gated by plugin install | Guaranteed context at session start; zero cost when plugin not installed |
| 2 | Plugin system (`compositions/plugins/`) with explicit install/remove | External tool dependency requires deliberate lifecycle management |
| 3 | Purpose-built tool, not MemPalace wrapper | We use 15% of MemPalace; SQLite exact backend is the useful core; avoid 200MB ChromaDB deps |
| 4 | `recall` CLI at `tools/recall/`, installed to PATH | Must work from any project; short name for token efficiency |
| 5 | Spike 6 embedding models before choosing | MiniLM, nomic-embed-text, embeddinggemma, snowflake-arctic, qwen3-0.6b, mxbai-embed-large |
| 6 | One global DB at `~/.recall/recall.sqlite3`, wing-tagged | Source data is global; cross-project search is valuable |
| 7 | Write-back: as-is + metadata (wing, room, type, source, created_at). 2000 char cap | Simple; agent controls granularity; type enables filtered injection |
| 8 | `recall prime` outputs instructions + data | Self-contained; skills/agents/eager-context can all point to it |
| 9 | Ingest auto-tags wing from session cwd metadata | Zero-config multi-project separation from existing data |
| 10 | Plugin state at `~/.crew-research/plugins.json` | Tool-agnostic; single source of truth for installed plugins |

---

## Architecture

```
~/.recall/
  recall.sqlite3          # vectors + FTS5 + metadata (single file)
  config.json             # wing aliases, topic_keywords overrides

~/.crew-research/
  plugins.json            # tracks installed plugins + versions

tools/recall/             # source in crew-research repo
  pyproject.toml          # installable via uv tool install
  recall/
    __init__.py
    cli.py                # entry point: search, add, ingest, prime, status
    embedder.py           # ONNX model loading (model TBD by spike)
    store.py              # SQLite: vectors as BLOB, FTS5, hybrid scoring
    normalize.py          # kiro-cli + codex JSONL parsers
    chunker.py            # exchange-pair chunking + room classification
```

## CLI Interface

```bash
# Search
recall search "query"                          # cross-project
recall search "query" --wing lacrosse_bosse    # scoped
recall search "query" --room decisions         # room filter
recall search "query" --results 10             # more results

# Write-back
recall add "We chose field-relative yards" --wing lacrosse_bosse --room decisions --type decision
recall add "Chunking at 800 chars is too aggressive for architecture discussions" --type lesson

# Ingest
recall ingest ~/.kiro/sessions/cli             # auto-tag wings from cwd
recall ingest ~/.kiro/sessions/cli --project ~/code/lacrosse-bosse-platform
recall ingest ~/.codex/sessions/2026/06/16     # codex sessions

# Session start context
recall prime --wing lacrosse_bosse             # instructions + recent facts + top retrieval

# Status
recall status                                  # drawer counts by wing/room
```

## `recall prime` Output Format

```
## Recall — Memory System

Use `recall search "query"` before answering questions about past decisions.
Use `recall add "fact" --wing X --room Y --type decision` to persist learnings.

## Recent Memories (lacrosse_bosse)

- [decision] Field-relative yards for coordinate system (2026-06-16)
- [decision] Zero new autoloads for v1 execution slice (2026-06-16)
- [lesson] Chunking at 800 chars splits architecture discussions mid-thought (2026-06-18)

## Relevant Context

> Setting aside current state, what would an idealized architecture look like?
  PlayData should describe the authored play only... (source: rollout-2026-06-16)

> We should consider this a "ground up" rebuild.
  I'll treat that as a scope decision... (source: rollout-2026-06-16)
```

## Storage Schema

```sql
CREATE TABLE drawers (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  embedding BLOB NOT NULL,          -- float32 vector as bytes
  wing TEXT NOT NULL,
  room TEXT NOT NULL DEFAULT 'general',
  type TEXT DEFAULT 'fact',          -- decision|fact|lesson|preference
  source TEXT NOT NULL,              -- 'ingest:<filename>' or 'agent-write'
  source_file TEXT,                  -- original file path for ingest
  created_at TEXT NOT NULL           -- ISO 8601
);

CREATE VIRTUAL TABLE drawers_fts USING fts5(content, content_rowid='rowid');

CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT
);
-- meta keys: schema_version, embedding_model, embedding_dim
```

## Topic Keywords (configurable via `~/.recall/config.json`)

```json
{
  "topic_keywords": {
    "play_system": ["play", "playdata", "step", "action", "formation", ...],
    "architecture": ["state machine", "boundary", "orchestration", ...],
    "ai_and_gameplay": ["fielder_3d", "blackboard", "objective", ...],
    "planning": ["plan", "spec", "milestone", "phase", ...],
    "platform_infra": ["aws", "cdk", "ci", "pipeline", ...],
    "testing": ["gdunit", "test", "assert", "validation", ...],
    "decisions": ["decided", "chose", "recommendation", ...],
    "problems": ["problem", "broken", "crash", "workaround", ...]
  }
}
```

---

## Task Graph

```
Phase 0: Embedding Spike (blocking — determines core dependency)
  S1: Spike MiniLM (46MB, 384d, 256 tok)
  S2: Spike nomic-embed-text v1.5 (274MB, 768d MRL, 8192 tok)
  S3: Spike embeddinggemma (622MB, 768d MRL, 2K tok)
  S4: Spike snowflake-arctic-embed-m-v2.0 (296MB, 768d MRL, 8192 tok)
  S5: Spike qwen3-embedding:0.6b (639MB, 1024d MRL, 32K tok)
  S6: Spike mxbai-embed-large (670MB, 1024d, 512 tok)
  S1-S6 → D1: Choose embedding model based on spike results

Phase 1: Core Tool (depends on D1)
  D1 → T1: Scaffold tools/recall/ with pyproject.toml
  T1 → T2: Implement store.py (SQLite + FTS5 + exact cosine)
  T1 → T3: Implement embedder.py (ONNX model loading, chosen model)
  T1 → T4: Implement normalize.py (kiro-cli + codex parsers)
  T2, T3, T4 → T5: Implement chunker.py (exchange-pair + room classification)
  T2, T3, T5 → T6: Implement cli.py (search, add, ingest, prime, status)
  T6 → T7: End-to-end test: ingest 270 sessions, search, verify recall

Phase 2: Plugin System (can parallel with Phase 1 after T1)
  T1 → T8: Create compositions/plugins/ directory + manifest schema
  T8 → T9: Create compositions/plugins/recall.yaml
  T8 → T10: Add --plugin/--remove-plugin to init.sh
  T10 → T11: Implement ~/.crew-research/plugins.json state tracking
  T10 → T12: Add plugin status to doctor.sh

Phase 3: Skill + Eager Context (depends on T6)
  T6 → T13: Write atomics/skills/recall/SKILL.md
  T6 → T14: Write atomics/skills/recall/references/cli-reference.md
  T6 → T15: Write steering file for session-start prime injection

Phase 4: Eval Definitions (depends on T13)
  T13 → T16: Write activation proof (triggers on recall queries)
  T13 → T17: Write non-activation proof (silent on implementation)
  T13 → T18: Write dual-run effectiveness eval (with/without skill)
  T13 → T19: Write multi-condition experiment definition
  T18 → T20: Create eval fixture (pre-seeded recall DB with known content)

Phase 5: Experiment Execution (depends on T16-T20)
  T16, T17 → T21: Run activation proofs
  T18, T20 → T22: Run dual-run evals (3 trials)
  T19, T20 → T23: Run multi-condition experiment (4×3×3)
  T21, T22, T23 → T24: Analyze results, write findings
  T24 → T25: Final tier placement decision
```

---

## Phase Specs

### Phase 0: Embedding Spike

**Spec:** [specs/recall-embedding-spike.md](specs/recall-embedding-spike.md)

**Protocol (same for each model):**
1. Load model via ONNX runtime (no Ollama dependency)
2. Ingest 270 kiro-cli session files → measure wall time
3. Store in SQLite (exact cosine + FTS5 hybrid)
4. Run 5 known-answer queries → measure recall@3
5. Report: install size, ingest time, query latency (p50/p95), recall accuracy

**Acceptance criteria:**
- Ingest 270 files in < 5 minutes
- Query latency < 500ms
- Finds correct passage in top-3 for 4/5 test queries
- Install footprint documented

**Models:**
| ID | Model | ONNX source |
|----|-------|-------------|
| A | all-MiniLM-L6-v2 | sentence-transformers/all-MiniLM-L6-v2 |
| B | nomic-embed-text v1.5 | nomic-ai/nomic-embed-text-v1.5 |
| C | embeddinggemma | onnx-community/embeddinggemma-300m-ONNX |
| D | snowflake-arctic-embed-m-v2.0 | Teradata/snowflake-arctic-embed-m-v2.0 |
| E | qwen3-embedding:0.6b | (verify ONNX availability; may need GGUF conversion) |
| F | mxbai-embed-large | mixedbread-ai/mxbai-embed-large-v1 |

---

### Phase 1: Core Tool

**Spec:** [specs/recall-core-tool.md](specs/recall-core-tool.md)

**Components:**

`store.py` (~200 lines):
- SQLite with schema above
- `upsert(id, content, embedding, metadata)`
- `search(query_embedding, query_text, wing?, room?, n_results)` → hybrid BM25 + cosine
- `add(content, wing, room, type)` → single-row write-back
- `get_recent(wing?, type?, limit)` → for prime

`embedder.py` (~100 lines):
- Load ONNX model (lazy, cached)
- `embed(text) → list[float]`
- `embed_batch(texts) → list[list[float]]`

`normalize.py` (~150 lines):
- `parse_kiro_cli_jsonl(content) → list[(role, text)]`
- `parse_codex_jsonl(content) → list[(role, text)]`
- `detect_and_parse(filepath) → list[(role, text)]`

`chunker.py` (~80 lines):
- `chunk_exchanges(messages) → list[str]` (exchange-pair chunking)
- `classify_room(text, keywords) → str`

`cli.py` (~200 lines):
- Commands: search, add, ingest, prime, status
- `--wing`, `--room`, `--type`, `--results`, `--project` flags

**Total estimate:** ~700 lines Python

---

### Phase 2: Plugin System

**Spec:** [specs/recall-plugin-system.md](specs/recall-plugin-system.md)

**Manifest format:**
```yaml
# compositions/plugins/recall.yaml
name: recall
description: "Cross-session memory recall via the recall CLI"
version: "0.1.0"

prerequisites:
  commands:
    - name: recall
      check: "recall --version"
      install_hint: "cd ~/code/crew-research && uv tool install tools/recall/"

deploys:
  steering:
    - recall-session-start
  skills:
    - recall
```

**State file:** `~/.crew-research/plugins.json`
```json
{
  "installed": {
    "recall": {
      "version": "0.1.0",
      "installed_at": "2026-06-20T01:00:00Z",
      "tools": ["kiro-cli", "codex"]
    }
  }
}
```

**init.sh additions:**
- `--plugin <name>` — install plugin (check prereqs, deploy artifacts, update state)
- `--remove-plugin <name>` — remove deployed artifacts, update state
- Pruning logic respects plugin-deployed files (don't prune what a plugin owns)

---

### Phase 3: Skill + Eager Context

**Spec:** [specs/recall-skill.md](specs/recall-skill.md)

**SKILL.md (~60 lines):**
```yaml
---
name: recall
description: >
  Cross-session memory recall. Use when asked about past decisions,
  prior work, what was discussed previously, or to continue from
  where a session left off. Also use to persist decisions and lessons.
metadata:
  type: protocol
  invocation: both
  params:
    wing: ""
---
```

**Steering file (~10 lines):**
```markdown
At session start, if recall is available, run:
  recall prime --wing <project>
Internalize the output as session context.
```

---

### Phase 4: Eval Definitions

**Spec:** [specs/recall-evals.md](specs/recall-evals.md)

Dual-run eval tasks:
1. "What coordinate system did we choose for play data storage?"
2. "Continue the architecture work from last session."
3. "Should we add a new autoload for the ball state service?"

Multi-condition experiment:
- no-memory | handoff-only | recall-only | combined
- 3 tasks × 4 conditions × 3 trials = 36 runs

---

## Dependencies & Prerequisites

| Requirement | Status |
|-------------|--------|
| crew-research repo | ✅ Available |
| kiro-cli session data | ✅ 121 sessions across 10 projects |
| codex session data | ✅ 3 rollout files (Jun 16) |
| ONNX runtime | Install with recall tool |
| Embedding model | TBD by spike |
| Eval harness | ✅ Existing in crew-research |

## Risks

| Risk | Mitigation |
|------|------------|
| Spike model E (qwen3-0.6b) may not have ONNX export | Document; exclude from spike if not available without Ollama |
| 700 lines estimate grows | Core is well-scoped; defer features to v2 |
| Plugin system adds init.sh complexity | Keep manifest format minimal; one new code path |
| Eval fixture depends on having recall working | Phase 4 naturally follows Phase 1 |

## Open for v2 (not in scope)

- Automatic deduplication / conflict detection
- Consolidation (promote session → global)
- Multi-format ingest (Slack, ChatGPT exports)
- `recall forget` (selective deletion)
- Hooks for auto-ingest after each session
