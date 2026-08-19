---
id: "114"
title: "Write activation + effectiveness evals for rewritten project-cleanup"
status: open
blocked_by: []
priority: high
---

# Write activation + effectiveness evals for rewritten project-cleanup

## Intent source

Session 2026-08-18: project-cleanup was rewritten as an end-of-session orchestrator (merged project-audit, added subagent dispatch, disambiguation gate enforcement). Needs eval coverage to verify activation triggers work and the skill produces correct behavior.

## What to build

Two eval definitions:
1. **Activation eval** — does the skill trigger on "wrap up" / "clean up" / "before handoff" and NOT on unrelated tasks?
2. **Effectiveness eval** — when loaded, does it correctly detect issues, apply the disambiguation gate, dispatch subagents, and route content?

## Acceptance criteria

- [ ] `tools/evals/definitions/activation-project-cleanup.yaml` written and parses
- [ ] `tools/evals/definitions/effectiveness-project-cleanup.yaml` written with fixture
- [ ] Fixture directory created with known issues (stale scratch, bloated CONTEXT.md, over-budget AGENTS.md, ticket drift)
- [ ] Dry-run passes for both definitions
- [ ] Activation eval: TPR ≥ 0.5, FPR ≤ 0.2 gates configured
- [ ] Effectiveness eval: threshold ≥ 3.5, delta ≥ 1.0 configured

## Out of scope

- Running the full eval suite (separate session)
- Modifying the skill based on eval results (that's a follow-up)
