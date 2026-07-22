---
id: "05"
title: "The 7 flagged eval definitions run as designed"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Flagged eval definitions run as designed

## What to build

Every active eval definition executes with real inputs (no null-input tasks, no missing fixture files, no identical A/B conditions) so scores measure skill behavior, not harness artifacts.

## Context

- **Relevant files:** `.memory/review-2026-07/eval-verdicts.md` (FIX table), effectiveness1/2.md
- **Schema:** `tools/evals/README.md`

## Acceptance criteria

- [x] architecture-deepening-rubber-stamp: single-turn (transcript embedded in input), runs without null input
- [x] agents-md-authoring-effectiveness: 300-line AGENTS.md embedded or added to fixture
- [x] context-budget-effectiveness: referenced .scratch file added to fixture or task rewritten
- [x] context-neutrality-effectiveness: conditions actually differ (encode the dispatch contrast) or eval retired — **retired** (moved to `definitions/retired/`, verified 2026-07-16)
- [x] handoff-improves-continuity: merged with handoff-decaying-resolution or differentiated
- [x] spec-validator-agent-effectiveness: conditions match the description (subagent dispatch) or description corrected
- [x] verification-protocol-improves-completion: task has headroom (not hello-world ceiling)
- [x] Each fixed eval runs once (`mise run eval:one`) without harness warnings

## Out of scope

- Re-baselining the whole suite (ticket 09)

## Resolution
**Closed:** 2026-07-16 (Resolution backfilled 2026-07-22). All 7 flagged eval definitions fixed or retired — multi-turn rewritten single-turn, missing fixtures embedded/added, descriptions matched to conditions, hello-world ceiling replaced, handoff-improves-continuity retired; validation runs 4✅/1❌ with zero harness warnings and zero null inputs (the ❌ is genuine skill signal). Evidence: docs/plan.md follow-up table row 05 ("✅ done (815fbe2 + validation runs: 4✅/1❌)"); work commit 815fbe2, status→done in 5d4fff5.
