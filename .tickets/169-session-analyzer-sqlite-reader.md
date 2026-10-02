---
id: "169"
title: "session-analyzer: read v3 SQLite sessions before JSONL dual-write stops"
status: open
blocked_by: ["168"]
tags: [kiro-v3]
---

# session-analyzer: read v3 SQLite sessions before JSONL dual-write stops

## The silent-failure risk

`tools/session-analyzer/session_review.py` (and the `mise run session:parse` /
`session:skills` tasks) read interactive transcripts from
`~/.kiro/sessions/cli/*.jsonl`. **Four files read that JSONL tree** (review 06,
file:line): `session_review.py:97,201`, `parse.py:6,36-44,58`,
`extract_batches.py:24,29,37`, `skill_usage.py:79` — the AC checklist originally
named only `session_review.py`; all four need the fix. kiro-cli v3 moved sessions
to **SQLite**:

- Linux: `~/.local/share/kiro-cli/data.sqlite3`, table `conversations_v2`
  (`key` = session cwd, `conversation_id`, `value` = conversation JSON text,
  `created_at`/`updated_at` unix ms). Verified live 2026-10-02 (10,984 rows).
- macOS: `~/Library/Application Support/kiro-cli/data.sqlite3`.

**On 2.27.0 both stores are live** (JSONL verified being written seconds-fresh
alongside the 3.5 GB SQLite DB), so nothing is broken yet. The migration guide
says v2 sessions are NOT auto-migrated and users should back up `~/.kiro/sessions`
before upgrade — strong signal that a true 3.0 build **stops the JSONL dual-write**.
When that lands, session-analyzer silently reads an empty/stale tree and reports
success on zero data (the "absence from a listing ≠ absence" trap). This is a
measurement-integrity bug that hides itself.

## What to build (after spike 168 confirms v3 schema)

1. **SQLite reader path** in `session_review.py`: when `data.sqlite3` exists, read
   `conversations_v2` (open **read-only** — third-party tools like `kiro-cli-history`
   do), parse `value` JSON per conversation keyed by project dir.
2. **Version/format detection**: prefer SQLite when present and newer than the JSONL
   tree; keep JSONL path as fallback for v2 users. Do NOT hard-cut JSONL — one
   deploy still serves both v2 and v3 users (deprecation, not removal).
3. **Map the `value` JSON shape** to the existing message/role model the analyzer
   expects (spike 168 / recall-74 will have characterized it; reuse that mapping —
   do not re-derive).
4. **Guard against zero-data success**: if neither store yields sessions for the
   requested window, the task must report "no sessions found (checked JSONL + SQLite)"
   loudly, not exit 0 silently.
5. **Replace the dormant wrong-surface v3 path** (review 06): `parse.py:41-44,58` and
   `extract_batches.py` already glob `~/.kiro/sessions/<hash>/sess_*/messages.jsonl`
   as a presumed "v3" layout — that layout **never populated** (0 files ever); the
   real v3 store is SQLite. Replace this dead path, don't leave it beside the new one.
   `extract-session-summary.sh:49-73` is already v2/v3-aware for the JSONL *line*
   format and is reusable for mapping — but its "v3" is the messages.jsonl line shape,
   not the SQLite `value`; confirm against the real `conversations_v2.value`.

## Coordination

The parsing logic overlaps recall's SQLite reader (recall ticket 74). Characterize
the `conversations_v2.value` JSON **once** (in spike 168 or recall-74) and share the
field map; don't reverse-engineer it twice. recall is the owner of the canonical
session-parsing patterns (`parse_kiro_v2` in `src/ingest.rs`).

## Acceptance criteria

- [ ] All four JSONL readers updated — `session_review.py`, `parse.py`, `extract_batches.py`, `skill_usage.py` — read `conversations_v2` from `data.sqlite3` (read-only) on both Linux + macOS paths
- [ ] Dormant `sess_*/messages.jsonl` v3 glob in `parse.py`/`extract_batches.py` replaced (not left beside the SQLite path)
- [ ] JSONL path retained as fallback; SQLite preferred when present
- [ ] `value` JSON mapped to the analyzer's message model (reusing spike/recall field map)
- [ ] Zero-data case reports loudly (no silent exit 0 on empty window)
- [ ] `mise run session:parse` + `session:skills` produce equivalent output from a v3 SQLite session vs the old JSONL path (parity check)
- [ ] No write access to the SQLite DB (read-only open verified)
