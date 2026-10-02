---
id: "171"
title: "Port SQLite session reader into parse.py/extract_batches.py/skill_usage.py when SQLite becomes the live store"
status: backlog
blocked_by: []
tags: [kiro-v3]
---

# Port SQLite reader into the secondary session-analyzer scripts

## Context

Ticket 169 added the v3 SQLite reader (`iter_sqlite_conversations` +
`scan_v3_conversation`) and freshness-based source selection to **`session_review.py`**
(the primary self-improvement probe), with the shared `value` field map in
`tools/session-analyzer/v3-sqlite-format.md`.

The three SECONDARY scripts — `parse.py` (metrics), `extract_batches.py` (batch
summaries), `skill_usage.py` (skill activation) — still read only the JSONL tree. Their
dead `sess_*/messages.jsonl` glob (a wrong-surface guess that never populated) was
removed in 169 and each warns on empty input, but they do NOT yet read SQLite.

**Why deferred, not done:** verified 2026-10-02 that on kiro-cli 2.27.0 the LIVE store
is JSONL — SQLite `conversations_v2` is frozen at 2026-09-01 here. So these scripts work
correctly today. Retrofitting the SQLite `value`-object parser into their file-based
parsers is real work with no current payoff and some risk.

## Trigger to activate (move off backlog)

When SQLite becomes the live store on a target build — detectable as
`max(conversations_v2.updated_at)` leading the newest `~/.kiro/sessions/cli/*.jsonl`
mtime (the exact comparison `session_review.py` already makes). At that point these
three scripts would silently read a stale/empty JSONL tree.

## What to build

- Factor `session_review.py`'s SQLite reader + freshness selector into a shared helper
  (e.g. `session_source.py`) and import it in all four scripts (avoid 4 copies).
- Map `conversations_v2.value.history` turns to each script's model per
  `v3-sqlite-format.md` (user.content.Prompt.prompt; assistant.ToolUse.tool_uses[].name;
  user.content.ToolUseResults; env_state.current_working_directory).
- Parity check: `mise run session:parse` + `session:skills` produce equivalent output
  from a v3 SQLite session vs the JSONL path.
- Read-only SQLite open; zero-data loud warning (both already patterns in 169).

## Acceptance criteria

- [ ] Shared source helper imported by session_review.py + parse.py + extract_batches.py + skill_usage.py
- [ ] All three secondary scripts read `conversations_v2` (read-only) when SQLite is the fresher store
- [ ] Parity check passes (SQLite vs JSONL equivalent output)
- [ ] Zero-data loud warning in all three
