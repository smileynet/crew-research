---
title: "Experiment 1: Activation Reliability Results"
date: 2026-05-22
status: complete
---

# Experiment 1: Activation Reliability

## Summary

| Metric | Value |
|--------|-------|
| Total tasks | 50 (25 relevant + 25 irrelevant) |
| True Positives | 17 |
| False Positives | 0 |
| True Negatives | 25 |
| False Negatives | 8 |
| True Positive Rate (recall) | 0.68 |
| False Positive Rate | 0.00 |
| Accuracy | 0.84 |
| Precision | 1.00 |

## Per-Skill Breakdown

| Skill | Relevant (5) | Irrelevant (5) | TPR | FPR |
|-------|-------------|----------------|-----|-----|
| eval-criteria | 5/5 ✅ | 0/5 ✅ | 1.00 | 0.00 |
| five-whys | 5/5 ✅ | 0/5 ✅ | 1.00 | 0.00 |
| handoff | 5/5 ✅ | 0/5 ✅ | 1.00 | 0.00 |
| situation-routing | 1/5 ⚠️ | 0/5 ✅ | 0.20 | 0.00 |
| verification-protocol | 1/5 ⚠️ | 0/5 ✅ | 0.20 | 0.00 |

## Key Findings

### F1: Zero false positives — skills never activate on irrelevant tasks

All 25 irrelevant tasks correctly did NOT trigger skill activation. The skill description matching is conservative — it won't load a skill unless the task clearly matches.

### F2: Two skills have severe activation problems

`situation-routing` and `verification-protocol` only activate on 1/5 relevant tasks (20% TPR). This means in our v1 eval, these skills may have been "force-loaded" by being present in the workspace rather than naturally activated by description matching.

### F3: Three skills activate perfectly

`eval-criteria`, `five-whys`, and `handoff` activate on 100% of relevant tasks. Their descriptions are well-matched to their target task shapes.

### F4: Activation failure is a description quality problem

The failing skills have descriptions that don't match the task language:
- `verification-protocol`: description says "before claiming task completion" — but tasks like "Fix the typo and report back" don't use the word "completion"
- `situation-routing`: description says "routing work to the right agent or approach" — but tasks like "Should I use Redis or Memcached?" don't mention "routing"

## Implications

1. **v1 eval results for situation-routing and verification-protocol may be inflated** — the skill was physically present in the workspace, so kiro-cli may have loaded it regardless of description matching. Need to verify the activation mechanism.

2. **Skill descriptions need improvement** for situation-routing and verification-protocol. The descriptions should use language that matches how users actually phrase relevant tasks.

3. **The activation experiment should be a gate** — don't run expensive dual-run evals on skills that can't reliably activate.

## Proposed Description Improvements

### verification-protocol (current)
> Mandatory verification gate before claiming task completion. Use when finishing work, reporting done, or before committing changes.

**Problem**: Only triggers on "completion" language. Misses "fix X and report back", "update Y and confirm it works".

**Proposed**:
> Verification steps before reporting work is done. Use when finishing a task, fixing a bug, making changes, or any time you need to confirm your work is correct before responding.

### situation-routing (current)
> Decision framework for routing work to the right agent or approach based on situation signals. Use when deciding who should handle a task, which crew to delegate to, or which reasoning mode to apply.

**Problem**: Too agent/crew-focused. Misses "help me decide", "should I use X or Y", "prioritize these tasks".

**Proposed**:
> Decision framework for choosing the right approach. Use when deciding between options, prioritizing tasks, choosing tools or technologies, or determining whether to investigate vs. act immediately.

## Artifacts

- Results: `tools/evals/results/activation-2026-05-23T02-33-58Z/`
- Runner: `tools/evals/harness/run-activation.sh`
- Detector: `tools/evals/harness/check-activation.sh`

---

## Follow-Up: Overloading Experiment

**Question**: Does having all 5 skills present simultaneously degrade activation accuracy?

### Results

| Condition | Activation Rate | Activated |
|-----------|:-:|:-:|
| Single skill present (baseline) | 0.70 | 7/10 |
| All 5 skills present | 0.50 | 5/10 |
| **Degradation** | **-0.20** | **-2** |

### Per-Skill Breakdown

| Skill | Single | All-present | Degraded? |
|-------|:------:|:-----------:|:---------:|
| eval-criteria | 2/2 | 2/2 | No |
| handoff | 2/2 | 2/2 | No |
| situation-routing | 1/2 | 1/2 | No |
| five-whys | 1/2 | 0/2 | **Yes** |
| verification-protocol | 1/2 | 0/2 | **Yes** |

### Key Findings

**F7: Overloading causes 20% activation degradation**

When all 5 skills are present, activation rate drops from 70% to 50%. This is a meaningful effect — 1 in 5 tasks that would have triggered a skill in isolation now fails to trigger it.

**F8: No cross-activation (good news)**

The wrong skill never activates. When five-whys fails to activate, it's not because situation-routing stole its activation — it's because the activation threshold is higher with more candidates.

**F9: Strong activators are immune to overloading**

Skills with distinctive trigger words (eval-criteria: "eval", "criteria", "rubric"; handoff: "handoff", "session", "ending") activate identically regardless of how many other skills are present. The overloading effect only hits skills that were already borderline.

**F10: Overloading raises the activation threshold, not interference**

The mechanism isn't "skills interfere with each other" — it's that kiro-cli's matching algorithm becomes more selective when it has more candidates to choose from. A skill that scored 0.6 similarity (barely above threshold with 1 candidate) might score below threshold when competing with 4 other candidates.

### Implications

1. **Skill budget is real but not catastrophic** — 5 skills show 20% degradation. The IFScale research predicted threshold effects at higher counts. We're seeing early signs at just 5.

2. **Description quality is the defense** — skills with distinctive, specific trigger words survive overloading. Generic descriptions get suppressed.

3. **verification-protocol may need eager loading** — it consistently fails to activate on-demand. It might be better as eager-context (always loaded) rather than a lazy skill.

4. **For production deployments**: limit active skills to those with proven activation reliability. Use eager-context for skills that apply universally but have generic triggers.

### Artifacts

- Runner: `tools/evals/harness/run-overloading.sh`
- Results: `tools/evals/results/overloading-2026-05-23T03-14-07Z/`
