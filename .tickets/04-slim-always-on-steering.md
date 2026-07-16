---
id: "04"
title: "Always-on steering costs ~450 lines instead of 812"
status: open
blocked_by: []
spec: "project-review-followup"
---

# Always-on steering is slimmed to earn its context cost

## What to build

Every line of always-on steering earns its place on every turn. Duplicated rules (stated 2-3× within a file, or duplicating the system prompt) are collapsed; project-specific content is demoted from global to project level.

## Context

- **Relevant files:** `.scratch/skill-review/batch5.md` (full analysis with line targets)
- **Targets:** ai-generation-hygiene 93→~40 (same 9 rules stated 3×); project-conventions ~318 effective→cut system-prompt dups, demote tool-installation.md to project-level, OS-gate windows.md; subagent-reliability 137→≤95 ("never inline" stated 3×); context-budget-awareness drop "When to Restart" (conflicts with system prompt)

## Acceptance criteria

- [ ] Batch-5 steering total ≤500 always-on lines (from 812)
- [ ] No rule stated more than once per file
- [ ] tool-installation.md not deployed globally (project-level or on-demand reference)
- [ ] context-budget-awareness no longer contradicts the system prompt's context_awareness section
- [ ] ai-generation-hygiene eval (activation-ai-generation-hygiene) still passes after trim
- [ ] Redeployed; doctor healthy

## Out of scope

- Changing WHAT the rules say (only how many times / where they're said)
