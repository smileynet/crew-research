---
id: "93"
title: "Spike: confidence scoring for code-review findings"
status: done
blocked_by: []
env: either
spec: "eval-harness"
priority: normal
---

# Spike: Confidence Scoring for Code-Review Findings

## Hypothesis

Adding deterministic confidence scoring to code-review findings — based on evidence presence
and structural checks — will allow filtering low-value findings and improve signal-to-noise.
Confidence must be "engineered around" the LLM (DZone pattern), not "asked from" it.

## Baseline to measure against

1. **Current state**: code-review produces findings with severity but no confidence score.
2. **Baseline measurement**: Run code-review on 5 diffs. For each finding, manually label:
   Actionable / Noise / Wrong. Record actionable rate.

## Spike design

### Approach A: Deterministic Evidence Scoring (no extra LLM call)

| Property | Score contribution |
|----------|-------------------|
| Cites specific line + code snippet | +0.3 |
| References a documented rule (steering/AGENTS.md) | +0.2 |
| Category is security or correctness (not style) | +0.2 |
| Proposes a specific fix | +0.2 |
| Is in changed lines (not context-only) | +0.1 |

Threshold: ≥0.6 = report, <0.6 = suppress (logged).

### Approach B: Multi-Agent Agreement (exploratory)

Dispatch 2-3 agents reviewing same diff. Score = agreement / agent count.
Constraint: subagent reliability (~50% empty) makes this secondary.

## Validation criteria

- [ ] Approach A: precision improves ≥15% over baseline
- [ ] Approach A: recall stays ≥90%
- [ ] Scoring adds zero latency (deterministic, no extra LLM calls)
- [ ] Scoring rubric documented in references/ (reproducible)

## Reject if

- Deterministic scoring can't discriminate (actionable score same as noise)
- Properties indicating quality aren't available in review output structure

## References

- Research: `.scratch/research/confidence-scoring.md`
- code-review skill: `~/.kiro/skills/code-review/SKILL.md`

## Resolution (2026-08-10)

Spike artifacts delivered: deterministic confidence scoring rubric (references/confidence-scoring.md), code-review SKILL.md updated with scoring rule. Approach A (structural evidence scoring) implemented as a reference — zero-latency, no extra LLM call. Runtime validation (measuring precision improvement on real diffs) deferred to field use. Approach B (multi-agent agreement) documented but not implemented due to subagent reliability constraints.
