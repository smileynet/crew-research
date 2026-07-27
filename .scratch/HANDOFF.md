---
created_at: 2026-07-27T07:55:00-07:00
base_commit: 32df7f1
handoff_key: skill-audit-deploy-cycle
---

# Handoff

## Objective
Skill consolidation + eval-driven improvements cycle. Consolidated skills, built new steering (research-dispatch-mandate, frontier-work), created ticket-planning skill, deployed tkt CLI, and ran full eval suite.

## Constraints
- Skills must stay <100 lines (references/ for overflow)
- `kiro_default` is the correct primary agent — never set a custom agent as `chat.defaultAgent` (AGENTS.md constraint)
- Full eval suite takes ~30 hours (103 defs × 3 trials × 4-model consensus judging)
- Eval harness edits MUST NOT happen while a run is executing (bash re-reads mid-execution)

## Prior Decisions
- 12 skills merged into parent references/ (eval-verified, all delta ≥ -0.5)
- 5 merges blocked by eval (feedback-loop, research-output, agents-md-authoring, changelog-discipline, ux-walkthrough) — keep standalone
- 2 skills removed (situation-routing Δ=0, research-topics superseded by steering)
- research-dispatch-mandate: strongest steering measured (Δ=+3.66)
- code-review: Pocock-inspired axis separation (floor-raising, PASS when activated)
- feedback-loop: enforcement language rewrite (Δ: 0→+0.89)
- recall_agent removed as default — kiro_default correct for primary sessions
- tkt CLI built and deployed (tools/tkt/, `uv tool install -e ./tools/tkt`)
- v0.2.0 released (2026-07-18)

## Current State
Plan: `docs/plan.md` (authoritative). Frontier: tickets 23, 30-36, 39, 46, 47 (see `tkt ready`). Full eval baseline at 28/35 judged pass (80%). Recall ingest running on cron (every 4h), 14,251 drawers indexed. All tools deployed (kiro-cli, codex, agy) at full tier.

## Next Steps
1. Work the frontier (`tkt ready`) — tickets 23, 30-36, 39, 46, 47 are open
2. Unreviewed research: links batch (reflexion, walking skeleton, SysML, Petri nets, PRISM, DDD bounded contexts) — dispatched but interrupted in earlier session
3. OpenAI 5.6 integration — Terra as eval target, Luna as judge candidate (findings in `.scratch/research/openai-5.6-models.md`)

## Evidence
- Eval results: `tools/evals/results/2026-07-15T03-50-09Z/` (103 defs, 9 pass/94 fail — mostly activation threshold + model-caught-up)
- Eval baseline: `docs/development/eval-baseline-2026-07-19.md` (28/35 judged)
- Consolidation spec: `.memory/specs/skill-audit-consolidation.md` (Phase 3 results)
- Research: `.scratch/research/` (pocock-tickets, openai-5.6-models, local-ticket-tools, harness docs)
