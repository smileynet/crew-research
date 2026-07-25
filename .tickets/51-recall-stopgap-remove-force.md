---
id: "51"
title: "Stopgap: remove --force from Invoke-RecallIngestAll.ps1"
status: done
blocked_by: []
env: either
spec: "recall-import-fix"
priority: high
---

# Stopgap: remove --force from Invoke-RecallIngestAll.ps1

## What to build

Remove `--force` from the `recall import` calls in `Invoke-RecallIngestAll.ps1` (and `ingest-all.sh` for Linux/macOS). This stops the cross-wing data loss immediately.

## Context

- **Observed (2026-07-25):** `--force` executes `DELETE FROM drawers WHERE source LIKE 'import:%'` — a global wipe of ALL wings' imported data, not scoped to the wing being imported. The ingestion script loops N projects with `--force` each, so projects 1 through N-1 get their imports nuked by the final iteration. Only the last project retains imports.
- **Evidence:** DB analysis shows 91 import drawers from 1 wing (system-health, the last project processed), vs the expected ~500+ across 11 projects with `.memory/` dirs.
- **Trade-off accepted:** Without `--force`, changed `.memory/` files won't update until ticket 53 (hash-gate) ships. This is acceptable because: (a) `.memory/` content changes rarely, (b) losing all imports is far worse than stale imports.
- **Also remove from `ingest-all.sh`** (Linux/macOS equivalent) for parity.

## Acceptance criteria

- [ ] `Invoke-RecallIngestAll.ps1` calls `recall import` without `--force`
- [ ] `ingest-all.sh` calls `recall import` without `--force` (if it uses --force)
- [ ] After a full ingestion run, ALL projects with `.memory/` dirs have their wing present in `recall status`
- [ ] Session ingestion behavior unchanged (it never used --force)

## Out of scope

- Fixing the --force implementation itself (ticket 52)
- Content-change detection (ticket 53)
