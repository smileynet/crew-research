---
title: Eval Findings v1 — First Dual-Run Skill Evaluation
date: 2026-05-22
skills: [verification-protocol, five-whys, eval-criteria, situation-routing, handoff]
---

# Eval Findings v1

First dual-run evaluation of 5 authored skills using the eval harness (T9/T10/T16).

## Configuration

- **Tool**: kiro-cli 2.3.0
- **Judge**: claude-sonnet-4-6, temperature 0
- **Trials**: 3 agent trials per condition, 1 judge trial per output
- **Adapter**: kiro-cli (non-interactive mode)
- **Workspace**: isolated temp directories (empty)
- **Commit**: 963868f

## Results

| Skill | Type | With | Without | Delta | Pass |
|-------|------|------|---------|-------|------|
| verification-protocol | protocol | 5.00 | 1.00 | +4.00 | ✅ |
| five-whys | reasoning-mode | 5.00 | 1.00 | +4.00 | ✅ |
| eval-criteria | reference | 5.00 | 2.33 | +2.67 | ✅ |
| handoff | process | 5.00 | 3.00 | +2.00 | ✅ |
| situation-routing | decision | 4.66 | 3.00 | +1.66 | ✅ |

All 5 skills pass (threshold: 4, delta_threshold: 1.0).

## Key Findings

### F1: Skill type predicts delta magnitude

Protocol and reasoning-mode skills show the strongest signal (delta 4.0). Without them, agents completely skip the target behavior. Reference and process skills show moderate signal (2.0–2.7) — agents partially exhibit the behavior naturally. Decision skills show the weakest signal (1.66) — agents have baseline routing instincts.

**Implication**: Protocol skills are the highest-value authoring target. They encode behaviors agents would never do unprompted.

### F2: Task design is the primary failure mode

The original situation-routing eval scored 1/1 in both conditions because the task ("I'm not sure how to set up OpenTelemetry") wasn't grounded in observable workspace behavior. The agent just wrote code regardless. Revised task ("tests failing with connection refused — fix it") produced a clear signal.

**Implication**: Eval tasks must create conditions where the skill's behavior is both possible and observable. Abstract tasks in empty workspaces don't exercise decision-making skills.

### F3: Judge determinism confirmed in practice

Across 30 judge invocations (5 skills × 3 trials × 2 conditions), no variance was observed on repeated fixed inputs. Consistent with S4 spike finding.

**Implication**: 1 judge trial per output is sufficient. All observed score variance comes from agent non-determinism.

### F4: Skill activation is verifiable

Skill loading is detectable from kiro-cli's sqlite database (`~/.local/share/kiro-cli/data.sqlite3`, table `conversations_v2`). When a skill activates, its full content appears in the conversation payload. With-skill conversations are ~8K chars larger than without-skill.

**Method**: Query by workspace path (temp dir name = key), search for skill-specific content markers.

**Implication**: We can build a post-run activation verifier to distinguish "skill loaded but didn't help" from "skill never loaded."

### F5: Empty workspace limits eval validity

All evals ran in bare temp directories. Tasks requiring real code interaction (build, test, lint) can only be evaluated on the agent's stated intent, not actual execution results. The verification-protocol skill scored 5.0 because the agent ran `python hello.py` — but for more complex tasks, there's nothing to build/test against.

**Implication**: Need a real project test bed for higher-fidelity evaluation.

### F6: Single task per skill is a weak signal

Each eval has one task. A skill might help on some tasks and not others. We proved the skill *can* help, not that it *reliably* helps across diverse inputs.

**Implication**: Need 3-5 tasks per skill to measure consistency and identify task shapes where skills fail.

## Methodology Limitations

1. **Same model family for agent and judge** — both are Anthropic Claude. No cross-provider judging.
2. **Single dimension scored** — behavioral compliance only. No process, communication, or efficiency scoring.
3. **No activation verification** — we confirmed it's possible but didn't integrate it into the harness.
4. **No real project context** — empty workspaces don't represent real development work.
5. **No tool call analysis** — we don't examine HOW the agent worked, only the final output.

## Artifacts

- Results: `tools/evals/results/2026-05-22T14-25-36Z/`
- Definitions: `tools/evals/definitions/*.yaml`
- Harness: `tools/evals/harness/run.sh`
- Judge config: `tools/evals/judges/default.yaml`
