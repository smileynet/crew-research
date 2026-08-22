---
id: "122"
title: "Shadow execution: parallel model comparison on live tasks"
status: open
blocked_by: []
---

# Shadow execution: parallel model comparison on live tasks

## Intent

When running prompts against a primary agent/model, secondary agents run the same instruction in parallel as "shadows." We capture primary results, determine success against acceptance criteria, then evaluate whether shadow models (faster/cheaper) sufficiently met the same criteria. The goal: passively discover if cheaper models can handle tasks we're currently routing to expensive primaries.

This is NOT a benchmark suite — it's live, passive comparison on real work. No synthetic prompts. The signal is: "on the tasks we actually do, could a cheaper model have done it?"

## What to build

### Core system

1. **Shadow dispatcher** — intercepts a prompt going to the primary model and fans it out to N configured shadow models in parallel
2. **Result collector** — captures all responses (primary + shadows) with timing, token counts, cost
3. **Criteria evaluator** — given the task's acceptance/success criteria, judges whether each shadow response "sufficiently" meets them (not identical — functionally equivalent)
4. **Results store** — structured log of all shadow runs: task, models, verdicts, cost delta, timing delta

### Key design questions (needs grill/spike)

- **Where does interception happen?** Options:
  - Harness-level (wraps `opencode run`, `kiro-cli chat`, etc.) — tool-agnostic but loses context
  - Plugin-level (opencode plugin hook on `chat.message`) — deep integration but tool-specific
  - Eval-harness extension (run shadows as additional eval legs) — reuses existing infra
- **What counts as "sufficient"?** Options:
  - LLM-as-judge (same as eval harness consensus judging)
  - Criteria checklist (mechanical: did it produce a file? does it compile? tests pass?)
  - Hybrid: mechanical gates + LLM judge for quality
- **Which tasks get shadowed?** Options:
  - All tasks (expensive, noisy)
  - Only tasks with explicit acceptance criteria (cleaner signal)
  - Sampling (random N% of tasks)
- **How to handle tool use?** Shadow models will attempt tool calls — do we:
  - Run in a sandbox (real tools, isolated fs)?
  - Dry-run (capture tool call intent, don't execute)?
  - Skip tool-heavy tasks?

### Output format

```jsonl
{
  "task_id": "...",
  "prompt_hash": "...",
  "primary": { "model": "...", "tokens": N, "cost": 0.XX, "time_ms": N, "verdict": "pass" },
  "shadows": [
    { "model": "...", "tokens": N, "cost": 0.XX, "time_ms": N, "verdict": "sufficient|insufficient|error", "delta_notes": "..." }
  ],
  "criteria": ["...", "..."],
  "savings_if_shadow": "$X.XX per invocation"
}
```

### Metrics to track

- **Sufficiency rate** per model per task category: % of tasks where shadow could have replaced primary
- **Cost ratio**: shadow_cost / primary_cost when sufficient
- **Latency ratio**: shadow_time / primary_time
- **Failure modes**: what categories of tasks do cheap models consistently fail at?
- **Confidence over time**: running average with window (not just point estimates)

## Prior art / integration points

- `tools/evals/harness/run.sh` — existing model comparison infra (run.sh already supports `--model` flag per trial)
- `tools/evals/harness/judge-response.sh` — LLM-as-judge consensus scoring (reusable for shadow verdicts)
- OpenCode plugin system (`tool.execute.before/after`, `chat.message` hooks) — candidate interception point
- `compositions/agent-archetypes/` — model routing preferences already exist here

## Non-goals (for now)

- Automatic model routing (shadowing is observation only — humans decide when to switch)
- Real-time switching mid-session
- Replacing the eval harness (this complements it with live signal)

## Acceptance criteria

- [ ] Shadow dispatcher can fan out a prompt to N models in parallel
- [ ] Results collected with timing, tokens, cost for each model
- [ ] Criteria evaluation produces sufficient/insufficient verdict per shadow
- [ ] Results stored in queryable format (JSONL or SQLite)
- [ ] At least one integration point working (eval harness, opencode plugin, OR harness wrapper)
- [ ] Summary report: "model X was sufficient on Y% of tasks, saving $Z"
