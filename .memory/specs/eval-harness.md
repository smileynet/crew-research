---
type: specification
title: "Eval Harness Specification (Phase 2)"
status: active
---

# Eval Harness Specification (Phase 2)

## Overview

LLM-as-judge behavioral evaluation that validates agent decisions and skill effectiveness. Supports dual-run comparison (with/without skill) to prove skill value against baseline.

## Directory Structure

```
tools/evals/
├── adapters/          # reuses proof harness tool adapters
├── definitions/       # declarative eval specs (YAML)
├── judges/            # judge configurations
├── harness/           # isolation, invocation, scoring pipeline
└── results/           # per-run directories
```

## Eval Definition Format

```yaml
name: dispatcher-routes-augment
agent: dispatcher
input: "add a new agent to the general crew"

criteria: |
  PRIMARY: Delegates to crew-augmenter.
  AUTOMATIC FAIL (score 1): Delegates to wrong agent, OR does the work itself.
  BONUS (score 5): Narrates why this agent was chosen.

ideal: |
  Delegating to crew-augmenter — adding agents to existing crews is their specialty.

tags: [routing, meta-crew]
threshold: 4
timeout: 120
```

## Dual-Run Skill Evaluation Format

```yaml
name: verification-protocol-improves-quality
skill: verification-protocol
category: skill-effectiveness

tasks:
  - input: "Fix the null check bug in parse_config and report done."
    criteria: |
      PRIMARY: Agent runs verification checks before claiming done.
      AUTOMATIC FAIL (score 1): Claims done without running any checks.
      Score 5: Runs build + test, reads output, cites evidence in completion signal.

runs:
  with_skill: true     # skill loaded
  without_skill: true  # baseline (no skill)

threshold: 4
delta_threshold: 1.0   # minimum score improvement skill must provide
```

## Eval Definition Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Kebab-case identifier |
| `agent` | Yes (behavioral) | Agent to invoke |
| `skill` | Yes (dual-run) | Skill being evaluated |
| `input` | Yes | Prompt sent to agent |
| `criteria` | Yes | PRIMARY + AUTOMATIC FAIL + score anchors |
| `ideal` | No | Reference response for judge calibration |
| `tags` | No | For filtering (routing, scope, execution, skill-effectiveness) |
| `threshold` | Yes | Minimum passing score (4 = critical, 3 = quality) |
| `timeout` | No | Seconds (default: 120) |
| `delta_threshold` | No | Minimum improvement over baseline (dual-run only) |

## Criteria Style Guide

```
PRIMARY: The ONE thing being tested. One sentence.
AUTOMATIC FAIL (score 1): Condition that means instant failure.
Score 3: What partial credit looks like.
Score 4: What "good" looks like.
BONUS (score 5): What excellence looks like.
```

Rules:
- One primary signal per eval
- Automatic-fail is mandatory
- Countable over subjective
- Ideal responses on ambiguous evals

## Judge Configuration

```yaml
# tools/evals/judges/default.yaml
model: claude-sonnet-4-6    # different family from subject when possible
temperature: 0
scoring: reasoning-before-score
rubric: 5-point-likert
```

## Harness Behavior

### Standard Behavioral Eval
1. Create isolated temp workspace
2. Deploy agent config via adapter
3. Invoke agent with input
4. Send output + criteria to judge
5. Parse SCORE + REASON
6. Record result

### Dual-Run Skill Eval
1. Create isolated temp workspace
2. **Run A**: Deploy agent WITH skill loaded → invoke → score
3. **Run B**: Deploy agent WITHOUT skill (baseline) → invoke → score
4. Compute delta (Run A score - Run B score)
5. Pass if: Run A ≥ threshold AND delta ≥ delta_threshold

## Reliability

- Default 3 trials per eval (pass^k: majority must pass)
- Retry only on empty output or timeout (infrastructure failures)
- No retry on non-empty output (behavioral signal)
- Judge majority vote available for high-variance evals

## Task Validation (for dual-run evals)

Before accepting generated tasks, validate:
- **Criteria leakage**: task doesn't reveal the scoring criteria
- **Skill leakage**: task doesn't describe the skill's content
- **Value**: task tests skill-specific behavior, not generic competence

## Activation Testing (optional)

```yaml
name: verification-protocol-activates
skill: verification-protocol
category: activation

input: "Fix the bug and let me know when it's done."
expect_activation: true   # skill should auto-load for this input
```

Tests whether the skill's description triggers activation without forcing.

## Result Format

```
tools/evals/results/{timestamp}/          # one dir per run, ONE adapter per run
├── meta.json       # context: commit, tool version, adapter, config, summary
├── scores.jsonl    # one line per def: name, status, score, reason, per-task trial scores
└── outputs/        # RETAINED raw agent outputs: {def}-{condition}-task{N}-trial{M}.txt
```

Key properties (verified 2026-07-19):

- **Raw outputs are retained** — re-judging past runs is feasible: outputs + the def's criteria at `meta.json`'s recorded commit reconstruct the judge prompt.
- **Adapter is per-run** (meta.json), so cross-adapter comparison = sibling run dirs joined on def identity. A crush run of the same defs slots in beside a kiro run.
- **Judge artifacts are deleted** after scoring (only the median survives), and judge participation is not recorded — a degraded consensus (e.g., 2 of 4 judges reachable) is indistinguishable from a full one. Fix tracked in ticket 29.

### Known gaps (target schema — tickets 29/32)

| Gap | Impact | Fix |
|-----|--------|-----|
| scores.jsonl rows lack `id` (only mutable `name`) and `adapter` | joins break on rename; rows aren't self-describing outside their dir | ticket 29: emit `id` + `adapter` per row |
| Judge participation unrecorded | cross-machine consensus differences invisible | ticket 29: `judges: [names]` per row |
| No re-judge mode | can't upgrade old scores when more judges become reachable | ticket 32: `--judge-only <results-dir>` writing a versioned scores file (never overwrite) |
| `results/` is gitignored, no interchange format | runs from other machines (e.g., crush-capable) can't merge | ticket 32: export/import bundle or committed summary format; owed runs tracked in `docs/development/deferred-runs.md` |
| No result identity hashes | "does this result reflect current skill/def/model state?" requires git archaeology (a03798e confound precedent) | ticket 33: per-row `skill_hash`/`def_hash`/`env_id` + staleness checker + `--changed-only` |

## Result Fields (meta.json)

```json
{
  "tool": "kiro-cli",
  "tool_version": "2.3.0",
  "timestamp": "2026-05-18T01:13:58Z",
  "commit": "abc1234",
  "config": {"trials": 3, "threshold": 3, "judge": "claude-sonnet-4-6", "adapter": "kiro-cli"},
  "summary": {"total": 46, "passed": 38, "failed": 8, "avg_score": 4.1}
}
```
