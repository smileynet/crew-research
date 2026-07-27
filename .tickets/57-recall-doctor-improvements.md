---
id: "57"
title: "Recall doctor improvements: coverage, duplicates, health reporting"
status: done
blocked_by: ["56"]
env: either
spec: "recall-import-fix"
---

# Recall doctor improvements: coverage, duplicates, health reporting

## What to build

Improve `doctor.sh`'s recall checks to detect import coverage gaps, duplicate/split wings, and provide actionable health reporting.

## Context

- **Current doctor checks:** ingest staleness (last_ingest marker), cron presence, current project's wing chunk count. These are minimal — they didn't detect the --force nuke (all imports destroyed for weeks) or the hyphen/underscore wing split.
- **`recall status` is unreliable for parsing** — output contains ANSI escapes, inconsistent formatting. Doctor should use `recall search` or a purpose-built subcommand.

## Improvements

### D. Import coverage check
Scan `~/code/*/.memory/` (same discovery as the ingestion script) and verify each project has a corresponding wing in the DB with >0 import chunks. Missing wings = gap.

### E. Chunk count reporting
Report total drawers, import vs session split, and average freshness. Replace the current grep-based `recall status` parsing with something robust (JSON query or direct DB check via a new `recall health --json` subcommand).

### F. Duplicate/split wing detection
Detect wing names that differ only by hyphen/underscore and warn. The consolidation in ticket 56 prevents future splits, but doctor should detect any that sneak through.

### G. Import freshness per wing
If a project's `.memory/` files have mtimes newer than its wing's last import timestamp, warn about stale imports. (Prerequisite: ticket 53's sources manifest — before that, use file mtime vs `created_at` of newest import chunk in that wing.)

## Acceptance criteria

- [ ] Doctor detects missing import wings for discoverable projects
- [ ] Doctor warns about hyphen/underscore wing duplicates
- [ ] Doctor reports overall recall health: N wings, M total chunks, import coverage X/Y projects
- [ ] All new checks run without requiring `recall status` output parsing
- [ ] False-positive rate: zero on a healthy machine after tickets 51-56 are applied

## Out of scope

- Adding a `recall health` subcommand to the CLI (could be done here or separately)
- Fixing the `recall status` display itself (cosmetic — not blocking)

## Resolution (2026-07-27)

Added recall health --json subcommand. Rewrote doctor.sh recall checks to use JSON data. New: coverage gaps, duplicate wings, health summary. Zero false positives on healthy machine.
