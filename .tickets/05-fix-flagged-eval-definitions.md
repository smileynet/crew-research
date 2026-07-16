---
id: "05"
title: "The 7 flagged eval definitions run as designed"
status: open
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

- [ ] architecture-deepening-rubber-stamp: single-turn (transcript embedded in input), runs without null input
- [ ] agents-md-authoring-effectiveness: 300-line AGENTS.md embedded or added to fixture
- [ ] context-budget-effectiveness: referenced .scratch file added to fixture or task rewritten
- [x] context-neutrality-effectiveness: conditions actually differ (encode the dispatch contrast) or eval retired — **retired** (moved to `definitions/retired/`, verified 2026-07-16)
- [ ] handoff-improves-continuity: merged with handoff-decaying-resolution or differentiated
- [ ] spec-validator-agent-effectiveness: conditions match the description (subagent dispatch) or description corrected
- [ ] verification-protocol-improves-completion: task has headroom (not hello-world ceiling)
- [ ] Each fixed eval runs once (`mise run eval:one`) without harness warnings

## Out of scope

- Re-baselining the whole suite (ticket 09)
