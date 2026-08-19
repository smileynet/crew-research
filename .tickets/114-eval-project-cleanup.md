---
id: "114"
title: "Write activation + effectiveness evals for rewritten project-cleanup"
status: done
blocked_by: []
priority: high
validation_criteria:
  - "definitions parse (dry-run passes)"
  - "validation passes"
---

# Write activation + effectiveness evals for rewritten project-cleanup

## Intent source

Session 2026-08-18: project-cleanup was rewritten as an end-of-session orchestrator (merged project-audit, added subagent dispatch, disambiguation gate enforcement). Needs eval coverage to verify activation triggers work and the skill produces correct behavior.

## What to build

Two eval definitions:
1. **Activation eval** — does the skill trigger on "wrap up" / "clean up" / "before handoff" and NOT on unrelated tasks?
2. **Effectiveness eval** — when loaded, does it correctly detect issues, apply the disambiguation gate, dispatch subagents, and route content?

## Acceptance criteria

- [x] `tools/evals/definitions/activation-project-cleanup.yaml` written and parses
- [x] `tools/evals/definitions/effectiveness-project-cleanup.yaml` written with fixture
- [x] Fixture directory created with known issues (stale scratch, bloated CONTEXT.md, over-budget AGENTS.md, ticket drift)
- [x] Dry-run passes for both definitions
- [x] Activation eval: TPR ≥ 0.5, FPR ≤ 0.2 gates configured
- [x] Effectiveness eval: threshold ≥ 3.5, delta ≥ 1.0 configured

## Out of scope

- Running the full eval suite (separate session)
- Modifying the skill based on eval results (that's a follow-up)

## Resolution (2026-08-19)

Done

### Verification
1. ✓ definitions parse (dry-run passes) — "dry-run passes (39 run, 3 skip)"
2. ✓ validation passes — "mise run validate: 0 errors, tickets valid"
