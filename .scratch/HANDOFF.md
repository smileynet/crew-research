---
created_at: 2026-07-26T14:54:00-07:00
base_commit: 3bc1db8
handoff_key: recall-import-fix
---

# Handoff

## Objective
Fix recall's import/ingest pipeline — eliminate silent data loss, ensure all projects across all drives have their `.memory/` knowledge indexed.

## Constraints
- recall installed editable (`uv tool install -e ./tools/recall`) — source edits take effect immediately
- Wing names MUST be underscore-normalized (convention enforced in CLI + scripts)
- Source keys format is now `import:{wing}:{rel_path}` (schema v3)
- `--force` scoped to target wing only (never global DELETE)
- Ingestion scripts auto-discover `~/code` + `D:\code`

## Prior Decisions
- BUILD verdict for tkt CLI (ticket 38, prior session) — shipped and deployed
- recall adapted from MemPalace: SQLite+FTS5, hybrid search, batch ingestion (ADR 0007)
- Stopgap approach: remove --force from scripts immediately, proper fix (hash-gate) as follow-up
- Source key collision: wing prefix chosen over separate table (simpler, schema v3 migration)

## Current State
Tickets 51, 52, 56, 59(partial), 60 closed this session. recall DB healthy: ~24K chunks, 35+ wings, all discoverable projects imported. See `docs/plan.md` for full ticket status.

Research artifacts in `.scratch/research/`: recall-architecture.md, mempalace-prior-art.md, sqlite-fts-dedup.md, recall-session-ingest.md. Analysis in `.scratch/recall-import-analysis.md`. These inform tickets 53-55.

## Next Steps
1. **Ticket 53** (sources manifest + hash-gate) — unblocked, highest-value recall fix remaining. Design in ticket body + `.scratch/research/sqlite-fts-dedup.md` § "Recommended batch import job pattern"
2. **Ticket 58** (recall proofs) — unblocked, prevents regression on fixes shipped this session
3. **Ticket 59** (multi-root formalization) — `ingest-all.sh` and `profile-hook.ps1` fallback still need multi-root parity with the PS1 script
4. **Ticket 54** (session size tracking) — blocked on 53's sources table
5. **Ticket 57** (doctor improvements) — unblocked, lower priority than correctness fixes

## Fog
- Chunk-level embedding cache (ticket 55): heading-anchored chunking gives stable boundaries for cache hits, but no measurement of actual cache-hit rate exists. May be premature optimization.
- Whether `recall gc` (ticket 61) needs an interactive mode or dry-run-only is sufficient.

## Evidence
- DB audit script: `.scratch/recall-audit.py` (shows all wings, orphan detection)
- Wing consolidation: `.scratch/consolidate-wings.py` (one-time, already run)
- Research: `.scratch/research/recall-*.md` (4 subagent outputs)
