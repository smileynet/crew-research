---
title: Experiment Methodology
date: 2026-05-24
status: active
---

# Experiment Methodology

## Mental Model

```
Skill → loaded into agent context → changes agent behavior → measured by judge/metrics
```

We measure skill value through **controlled comparison**:
- **Independent variable**: skill presence (loaded / not loaded / compressed variant)
- **Dependent variables**: quality score, token usage, tool call patterns, activation rate
- **Controls**: same task, same agent, same tool, isolated workspace

## Process (for every experiment)

1. **Define** — write experiment spec (question, design, metrics, controls, acceptance criteria)
2. **Instrument** — ensure harness captures needed data
3. **Run** — execute with standard config (3 trials, fixture if needed)
4. **Extract** — pull metrics from results + sqlite conversation data
5. **Analyze** — compute statistics, compare conditions
6. **Document** — write findings with evidence, update skill/archetype if needed

## Standard Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Agent trials | 3 | Agent is non-deterministic; majority-pass |
| Judge trials | 1 | Judge is deterministic (S4 finding) |
| Judge model | claude-sonnet-4-6 | Different instance from subject |
| Timeout | 180s (fixture) / 90s (empty) | Fixture needs clone+install time |
| Fixture | defu (unjs/defu) | 197 LOC TypeScript, 23 vitest tests |
| Adapter | kiro-cli | Primary eval target |

## Data Sources

| Source | What it provides | How to access |
|--------|-----------------|---------------|
| Judge output | Quality score (1-5) + reason | Parsed from claude --print response |
| sqlite conversations_v2 | Full conversation payload | Query by workspace path (temp dir key) |
| Conversation payload | Skill activation, tool calls, token counts | JSON parse the value field |
| scores.jsonl | Per-eval results | Written by harness |
| meta.json | Run metadata | Written by harness |

## Key Invariants

- **Isolation**: every invocation gets a fresh temp directory
- **Reproducibility**: fixture is pinned (git clone from same repo)
- **Activation verification**: every with-skill run checks sqlite for actual loading
- **No leakage**: judge never sees skill content or which condition is being scored
- **Idempotent**: running the same experiment twice produces comparable results (within agent variance)

## Experiment Types

### Type A: Quality Comparison (existing)
Compare score with/without skill. Uses judge.
- Tool: `tools/evals/harness/run.sh`
- Output: scores.jsonl with with_score, without_score, delta

### Type B: Activation Test (existing)
Binary: did the skill load? No judge needed.
- Tool: `tools/evals/harness/run-activation.sh`
- Output: activation.jsonl with TP/FP/TN/FN

### Type C: Metric Extraction (new)
Extract token counts, tool call sequences, timing from conversation data.
- Tool: `tools/evals/harness/extract-metrics.sh` (to build)
- Output: metrics.jsonl with tokens, tool_calls, duration

### Type D: Multi-Condition (new)
Compare 3+ conditions (no skill, full skill, compressed skill, multiple skills).
- Tool: `tools/evals/harness/run-experiment.sh` (to build)
- Output: experiment.jsonl with per-condition scores and metrics

## Directory Convention

```
tools/evals/results/{experiment-name}-{timestamp}/
├── meta.json          # config, tool versions, commit
├── scores.jsonl       # quality scores (if applicable)
├── metrics.jsonl      # extracted metrics (tokens, tool calls)
├── activation.jsonl   # activation data (if applicable)
└── summary.json       # computed statistics
```
