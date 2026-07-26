---
id: "56"
title: "Normalize wing names in ingestion scripts and CLI --wing handling"
status: done
blocked_by: []
env: either
spec: "recall-import-fix"
priority: high
---

# Normalize wing names in ingestion scripts and CLI --wing handling

## What to build

Ensure wing names are always underscore-normalized regardless of entry path. Fix the ingestion scripts that pass raw hyphenated directory names, and make the CLI normalize `--wing` values on input so the split can never recur.

## Context

- **Observed (2026-07-26):** 7 projects have duplicate wings — sessions land under underscored names (e.g., `lacrosse_bosse`) while imports from `Invoke-RecallIngestAll.ps1` land under hyphenated names (e.g., `lacrosse-bosse`). Same project, split across two wings.
- **Root cause:** The PS1/bash scripts pass `$_.Parent.Name` (raw, with hyphens) as `--wing`. The CLI takes explicit `--wing` values as-is, bypassing its own `replace("-", "_")` normalization (which only fires on the auto-derived fallback).
- **Impact:** Scoped searches (`--wing lacrosse_bosse`) miss the 917 import chunks filed under `lacrosse-bosse`. Cross-wing search still works but results are suboptimal.

## Fixes (three sites)

1. **`Invoke-RecallIngestAll.ps1`** — normalize: `$wing = $_.Parent.Name -replace '-', '_'`
2. **`ingest-all.sh`** — normalize: `wing=$(echo "$wing" | tr '-' '_')`
3. **`profile-hook.ps1`** (fallback) — normalize the wing derivation
4. **`cli.py`** — normalize `args.wing` on input in `cmd_import` (and any other command that accepts `--wing`). This is the belt-and-braces fix so the split can never recur regardless of what callers pass.

## Acceptance criteria

- [ ] `Invoke-RecallIngestAll.ps1` produces underscore-normalized wing names
- [ ] `ingest-all.sh` produces underscore-normalized wing names
- [ ] `recall import .memory/ --wing foo-bar` stores chunks under wing `foo_bar` (CLI normalizes on input)
- [ ] After a full ingestion run, no hyphenated wing names exist in the DB
- [ ] `recall search "query" --wing crew_research` finds both import and session data for crew-research

## One-time cleanup

After the fix lands, consolidate existing duplicate wings:
```sql
UPDATE drawers SET wing = REPLACE(wing, '-', '_') WHERE wing LIKE '%-%';
```
This should be run once, then verified via `recall status`.

## Out of scope

- Changing the normalization character (underscore is the established convention from the CLI's own code)
- Wing rename/alias mechanism
