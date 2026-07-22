---
id: "04"
title: "Always-on steering costs ~450 lines instead of 812"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Always-on steering is slimmed to earn its context cost

## What to build

Every line of always-on steering earns its place on every turn. Duplicated rules (stated 2-3× within a file, or duplicating the system prompt) are collapsed; project-specific content is demoted from global to project level.

## Context

- **Relevant files:** `.memory/review-2026-07/batch5.md` (full analysis with line targets)
- **Targets:** ai-generation-hygiene 93→~40 (same 9 rules stated 3×); project-conventions ~318 effective→cut system-prompt dups, demote tool-installation.md to project-level, OS-gate windows.md; subagent-reliability 137→≤95 ("never inline" stated 3×); context-budget-awareness drop "When to Restart" (conflicts with system prompt)

## Acceptance criteria

- [x] Batch-5 steering total ≤500 always-on lines (from 812)
- [x] No rule stated more than once per file
- [x] tool-installation.md not deployed globally (project-level or on-demand reference)
- [x] context-budget-awareness no longer contradicts the system prompt's context_awareness section
- [x] ai-generation-hygiene eval (activation-ai-generation-hygiene) still passes after trim
- [x] Redeployed; doctor healthy

## Out of scope

- Changing WHAT the rules say (only how many times / where they're said)

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). Always-on steering slimmed 812→387 deployed lines (target ≤500) — each rule stated once per file, tool-installation demoted to project level, context-budget-awareness system-prompt conflict resolved, OS-gated steering refs in init.sh; activation-ai-generation-hygiene TPR .80 / FPR 0 / accuracy .90; redeploy idempotent, doctor healthy. Evidence: docs/plan.md follow-up table row 04 ("✅ done — batch-5 total 387 lines"); closing commit 2d4c164.
