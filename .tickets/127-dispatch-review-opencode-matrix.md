---
id: "127"
title: "Extend dispatch review to opencode with multi-model matrix"
status: open
blocked_by: []
priority: high
---

# Extend dispatch review to opencode with multi-model matrix

## Goal

Extend the independent-review dispatch (currently Codex-only, via the `dispatch-codex-review` skill) to ALSO use **opencode**, with the ability to run **multiple opencode sessions across a matrix of models**. This gives multi-model review coverage (different models catch different issues) instead of a single Codex perspective.

## Why

- `dispatch-codex-review` runs exactly one reviewer (Codex). Cross-model research (AGENTS.md "cross-model gap") shows models behave differently — a single reviewer has blind spots.
- opencode is unrestricted across all environments (corp/personal/unset), unlike agy — so it's safe to add everywhere.
- opencode supports many model backends, making it the natural vehicle for a model matrix.

## What to build

1. **Generalize the dispatch skill** (or add a sibling `dispatch-review` skill) so the reviewer tool is a parameter: `codex` | `opencode`. Preserve the existing correlation contract (RUN_ID, TARGET sha, committed+pushed findings ticket, result contract, fail-closed verification).

2. **opencode invocation** — determine the headless/non-interactive opencode command (equivalent of `codex exec --dangerously-bypass-approvals-and-sandbox`). Research opencode's run/exec flags and model-selection flag.

3. **Model matrix** — accept a list of models; launch one opencode session per model. Each session:
   - Gets its own RUN_ID (or shared RUN_ID + per-model sub-id) for correlation
   - Runs in isolation (own workdir/temp, per subagent-reliability + eval-execution containment rules)
   - Produces its own findings ticket OR a consolidated per-matrix aggregate — decide during design
   - Runs sequentially or bounded-parallel (respect subagent concurrency limits; one command at a time)

4. **Result aggregation** — reconcile findings across models: dedup overlapping findings, note model-specific catches, present a combined result. Cross-model dedup must happen in main context (subagent-reliability: cross-area merge is not a subagent task).

5. **Config** — where the model matrix is declared (compositions/? a dispatch config file? CLI flag?). Reference `known-tools.yaml` / adapter patterns.

## Open design questions (resolve before building)

- One findings ticket per model, or one aggregate with per-model sections?
- How to correlate N concurrent reviews to N tickets without collision (ID race)?
- Matrix source: hardcoded default set vs user-supplied list?
- Does opencode have a sandbox-bypass equivalent needed for running tests/linters + git push during review?
- Reuse `review-new-work` inside opencode (does opencode load crew skills the same way)?

## Acceptance criteria

- [ ] Dispatch review works with opencode (single-model) end-to-end: dispatch → findings ticket (correlated, pushed) → fail-closed verify
- [ ] Multi-model matrix launches N opencode sessions, one per model, isolated
- [ ] Findings correlated per-model with no ticket-ID collisions
- [ ] Cross-model findings aggregated/deduped in main context
- [ ] Codex path unchanged (no regression to `dispatch-codex-review`)
- [ ] opencode headless invocation + model-selection flag documented
- [ ] Skill (generalized dispatch-review) updated and cross-linked; validate passes
