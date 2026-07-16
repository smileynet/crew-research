---
id: "09"
title: "Clean post-review eval baseline exists"
status: blocked
blocked_by: ["01", "02", "03", "04", "05", "11"]
spec: "project-review-followup"
---

# Clean post-review eval baseline exists

## What to build

A full-suite eval run against the post-review skill set, producing the reference scores future changes are measured against. Runs on the cleaned suite (30 judged defs + 24 activation defs, isolation on, calibrated thresholds).

## Context

- **Relevant files:** `tools/evals/README.md`, `.kiro/steering/eval-execution.md` (nohup pattern — NEVER edit run.sh mid-run)
- **Blocked by 01-05** because skill content changes and eval fixes both move scores
- **Prior run:** 2026-07-15 (102/105, wedged at end; scores in results/2026-07-15T12-56-23Z)

## Acceptance criteria

- [ ] `mise run eval` full run completes without wedging (background, observed via sleep cycles)
- [ ] `mise run eval:activation` full run completes
- [ ] Results summarized: pass/fail counts, per-eval deltas vs 2026-07-15 run where comparable
- [ ] Failures triaged: real regression vs known gap (each classified)
- [ ] Baseline recorded in docs/development/ with date + commit hash

## Out of scope

- Fixing regressions found (new tickets per finding)
