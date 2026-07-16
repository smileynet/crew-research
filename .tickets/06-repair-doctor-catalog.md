---
id: "06"
title: "doctor.sh and catalog.sh report current reality"
status: open
blocked_by: []
spec: "project-review-followup"
---

# doctor.sh and catalog.sh report current reality

## What to build

`mise run doctor` verifies the things that actually break (extension deployment vs tier manifest, recall staleness/cron, frontmatter validity) and `mise run catalog` lists what actually exists (no dead prompts logic, working flags).

## Context

- **Relevant files:** `.memory/review-2026-07/tooling-audit.md` (doctor.sh + catalog.sh sections with line refs)

## Acceptance criteria

- [ ] doctor: reconciles deployed steering/skills against tier manifest + passing extensions (catches the frontier-work class of bug at deploy-target level)
- [ ] doctor: warns when ~/.recall/last_ingest >24h old or recall cron entry missing
- [ ] doctor: runs the lint frontmatter check (or reports lint status)
- [ ] doctor: GNU-only `grep -oP` replaced with portable equivalent
- [ ] catalog: dead prompts/[basic-prompt] logic removed; --tier and --category work as advertised or are removed from help
- [ ] Both scripts pass `bash -n` and run clean on this repo

## Out of scope

- proofs harness fixes (ticket 08)
