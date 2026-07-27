---
id: "61"
title: "Recall forget/gc command for wing cleanup and data maintenance"
status: done
blocked_by: []
env: either
spec: "recall-import-fix"
---

# Recall forget/gc command for wing cleanup and data maintenance

## What to build

Add `recall forget` and/or `recall gc` subcommands for removing stale wings, old data, or orphaned chunks without direct SQL.

## Context

- **Current state:** No way to remove a wing's data without `sqlite3` or `--force` reimport. When a project is deleted/moved, its session data persists indefinitely. True orphans are harmless at small scale but accumulate (currently ~154 chunks from 3 genuinely-gone projects).
- **Use cases:**
  1. Deleted a project permanently — want its session history removed
  2. Renamed a project — old wing name persists alongside new one
  3. Testing/scratch wings accumulated during development
  4. Age-based pruning for very old, low-relevance session data

## Proposed commands

```bash
# Remove all data for a wing
recall forget --wing old_project
# Outputs: "Deleted 150 chunks from wing 'old_project'"

# Remove data older than N days
recall gc --older-than 90
# Outputs: "Deleted 234 chunks older than 90 days (across 5 wings)"

# Dry-run mode
recall forget --wing old_project --dry-run
# Outputs: "Would delete 150 chunks from wing 'old_project'"

# List wings with no matching project (orphan detection)
recall gc --list-orphans --projects-root ~/code
# Outputs orphan wings with chunk counts
```

## Acceptance criteria

- [ ] `recall forget --wing X` removes all chunks for that wing (imports + sessions)
- [ ] `recall forget` requires explicit `--wing` (no accidental full-DB wipe)
- [ ] `recall gc --older-than N` removes chunks by `created_at` age
- [ ] Both commands support `--dry-run` (report what would be deleted)
- [ ] FTS5 index is rebuilt after deletions (consistency)
- [ ] A confirmation prompt for operations deleting >100 chunks (unless `--yes` flag)

## Out of scope

- Automatic scheduled GC (manual-only for now)
- Chunk-level deduplication (ticket 55)
- Wing rename/merge operations

## Resolution (2026-07-27)

Added recall forget (--wing required, --dry-run, --yes) and recall gc (--older-than N, --dry-run, --yes). Both rebuild FTS after deletion. All AC verified.
