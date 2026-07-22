---
id: "06"
title: "doctor.sh and catalog.sh report current reality"
status: done
blocked_by: []
spec: "project-review-followup"
---

# doctor.sh and catalog.sh report current reality

## What to build

`mise run doctor` verifies the things that actually break (extension deployment vs tier manifest, recall staleness/cron, frontmatter validity) and `mise run catalog` lists what actually exists (no dead prompts logic, working flags).

## Context

- **Relevant files:** `.memory/review-2026-07/tooling-audit.md` (doctor.sh + catalog.sh sections with line refs)

## Acceptance criteria

- [x] doctor: reconciles deployed steering/skills against tier manifest + passing extensions (catches the frontier-work class of bug at deploy-target level)
- [x] doctor: warns when ~/.recall/last_ingest >24h old or recall cron entry missing
- [x] doctor: runs the lint frontmatter check (or reports lint status)
- [x] doctor: GNU-only `grep -oP` replaced with portable equivalent
- [x] catalog: dead prompts/[basic-prompt] logic removed; --tier and --category work as advertised or are removed from help
- [x] Both scripts pass `bash -n` and run clean on this repo

## Out of scope

- proofs harness fixes (ticket 08)

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). doctor.sh and catalog.sh report current reality — tier-manifest reconciliation, recall staleness/cron warnings, source frontmatter validation, portable sed replacing grep -oP; catalog's dead prompts logic removed, --tier implemented, --category dropped; bash -n clean on all three scripts, doctor 0 errors/0 warnings on this repo. Evidence: docs/plan.md follow-up table row 06 ("✅ done (cd78f2c — tier reconciliation, recall staleness/cron, frontmatter lint, portable grep; catalog tags + --tier)"); closing commit cd78f2c.
