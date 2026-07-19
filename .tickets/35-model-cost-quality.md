---
id: "35"
title: "Model cost/quality benchmarking: prefer cheaper models where quality holds"
status: open
blocked_by: []
spec: "eval-harness"
---

# Model cost/quality benchmarking: prefer cheaper models where quality holds

## What to build

Evidence for model selection across the roles where WE choose the model, preferring lower-cost models that don't sacrifice quality. Output: a role → recommended-model table with the measurements behind it, applied to the configs we control.

## Roles in scope (where model choice is ours)

| Role | Today | Cost lever |
|------|-------|-----------|
| Consensus judge (kiro leg) | claude-opus-4.6 (`tools/evals/judges/default.yaml`) | a cheaper judge that agrees with the 4-judge median is nearly free quality |
| Eval judge trials generally | 4-model consensus per trial × ~700 judgments per full suite | biggest recurring spend in the repo |
| Automated session-review probes (ticket 34) | unbuilt — cost envelope is an explicit criterion | cheap prefilter/probe model decides feasibility |
| Background/lite subagent tasks (title gen, summaries) | ad hoc | meshclaw-lite precedent: text-only cheap model |
| Eval AGENT under test | user's default model | mostly NOT ours to change — evals measure skills under the model users run; flag but don't optimize |

## Method (use what exists — don't build a new harness)

1. **Judge-agreement study (cheapest, highest value):** retained outputs + recorded scores from `results/2026-07-19T00-29-50Z` (35 defs × trials) are a ready-made benchmark. Have candidate cheap models re-judge a sample (ticket 32's `--judge-only` machinery when it lands, or a one-off script now); measure agreement with the recorded consensus median (exact-match %, ±1 tolerance %, systematic bias direction). A candidate agreeing ≥ some threshold can replace/augment an expensive leg.
2. **small-model-\* def family** (5 defs exist: code-edit, code-summary, commit-message, instruction-following, tool-calling) is the existing vehicle for capability floors — run per candidate model via `--model`, compare against recorded thresholds.
3. **Record per the identity-hash scheme** (ticket 33): env_id distinguishes model runs; scores comparable by def id.
4. Cost data: per-model pricing from provider docs at measurement date, recorded alongside (prices drift — date-stamp them).

## Acceptance criteria

- [ ] Judge-agreement numbers for ≥2 cheaper candidates vs the 2026-07-19 consensus baseline (sampled, n stated)
- [ ] small-model def results per candidate at recorded commit
- [ ] Role → model recommendation table with cost + quality evidence, date-stamped; applied where a swap is justified (judges yaml), or documented why not
- [ ] Constraint respected: local machine lacks crush/agy access — candidate set limited to reachable models (kiro-cli `--model` list, codex); note what's untestable here (deferred-run ledger, ticket 29)

## Out of scope

- Changing the eval-agent-under-test default (measures the wrong thing)
- Provider pricing automation (a dated table suffices)
