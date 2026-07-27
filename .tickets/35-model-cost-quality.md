---
id: "35"
title: "Model cost/quality benchmarking: prefer cheaper models where quality holds"
status: in_progress
blocked_by: []
env: either
spec: "eval-harness"
---

# Model cost/quality benchmarking: prefer cheaper models where quality holds

## What to build

Evidence for model selection across the roles where WE choose the model, preferring lower-cost models that don't sacrifice quality. Output: a role → recommended-model table with the measurements behind it, applied to the configs we control.

## Judge tier policy (operator, 2026-07-27 — ADR 0010)

Grading and judging always use the best available model, or at minimum one tier above
the model being judged. **Judges are out of scope as a cost lever** — the cheap-judge
shadow study is a rejected alternative, not a deferred task. Cost work redirects to the
roles below where a cheaper model is documented-appropriate.

## Roles in scope (where model choice is ours)

| Role | Today | Cost lever |
|------|-------|-----------|
| Consensus judge legs | opus-5 / gpt-5.6-sol / glm-5.2 / agy-default (per ADR 0010) | **none — policy fixes this at family frontier** |
| Automated session-review probes (ticket 34) | prefilter is keyword-based; LLM confirm step | cheap prefilter/probe model — classification-shaped, which vendors DO endorse for small models |
| Background/lite subagent tasks (title gen, summaries) | ad hoc | meshclaw-lite precedent: text-only cheap model |
| Capability floors (`small-model-*` defs) | 5 defs exist | measures how far DOWN a model can go for agent work — informs the two rows above |
| Eval AGENT under test | tool default (`auto`) | NOT a cost lever; but see AC below — `auto` is nondeterministic and unrecorded |

## Method (use what exists — don't build a new harness)

1. **`small-model-*` def family** (code-edit, code-summary, commit-message,
   instruction-following, tool-calling) run per candidate via `--model`, compared
   against recorded thresholds. This is the capability-floor vehicle.
2. **Record per the identity-hash scheme** (ticket 33): env_id distinguishes model
   runs; scores comparable by def id.
3. Cost data: per-model pricing from provider docs at measurement date, recorded
   alongside (prices drift — date-stamp them). kiro-cli credit multipliers are a
   ready first-order proxy.

## Acceptance criteria

- [x] Documented size/intended-use positioning for the reachable candidate roster,
      cost excluded — `docs/development/model-positioning-2026-07-27.md`
- [x] Judge tier policy recorded (ADR 0010) and mechanically applied: all four leg
      models read from `judges/default.yaml`, legs upgraded to family frontier
- [ ] `small-model-*` def results per candidate at recorded commit (capability floor,
      not judge qualification)
- [ ] Role → model recommendation table with cost + quality evidence, date-stamped;
      applied where a swap is justified, or documented why not. Judge row reads
      "policy-fixed, see ADR 0010"
- [ ] Under-test model gap resolved or ticketed: `auto` records as `tool-default` in
      env_id, so neither the judged tier nor cross-run comparability is knowable
- [ ] Constraint respected (grill Q01): corp candidates = kiro-cli `--model` list,
      codex, and Bedrock via crush-bedrock; non-Anthropic Bedrock models
      (nova-lite/micro, glm, deepseek) only via direct `aws bedrock invoke-model` —
      spike before building. agy candidates: personal env only (corp = policy-blocked,
      ticket 36)

## Out of scope

- **Cheap consensus judges** (rejected, ADR 0010 — do not re-propose on cost grounds)
- Changing the eval-agent-under-test default for cost reasons (measures the wrong thing)
- Provider pricing automation (a dated table suffices)
