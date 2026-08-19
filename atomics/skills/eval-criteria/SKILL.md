---
name: eval-criteria
description: "Style guide for writing behavioral eval criteria that produce consistent LLM-judged scores. Use when creating, reviewing, or modifying eval definitions."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Eval Criteria Style Guide

## The Central Problem

LLM judges exhibit central tendency bias — scores cluster at 2-3 on a 1-5 scale regardless of actual quality. This is intrinsic (from RLHF training), not a prompt failure. The fix is structural: decompose holistic rubrics into binary checks.

## Preferred: Binary Checklist Criteria

Convert "score 3 vs 4" prose into independently verifiable YES/NO checks:

```yaml
criteria: |
  Score by counting independently verified checks (YES/NO):
  □ [observable behavior 1]
  □ [observable behavior 2]
  □ [observable behavior 3]
  ...
  AUTOMATIC FAIL (score 1): [condition]
  Scoring: 0-2 checks = 1, 3-4 = 2, 5-6 = 3, 7-8 = 4, 9-10 = 5
```

**Why this works:** Judges are ~87% accurate on binary decisions vs 38-58% on ordinal scales. The mechanical score derivation prevents clustering.

**Writing good checks:**
- Each check must be independently observable in the output (a grep could find it)
- Group by phase: DETECTION → CORRECT ACTION → METHODOLOGY
- 10-15 checks total is the sweet spot (fewer = coarse, more = judge fatigue)
- Harder checks (methodology, reasoning quality) count the same as easy ones — that's fine

## Fallback: Anchored Ordinal (when checks don't fit)

For evaluating quality/style where binary checks are unnatural:

```yaml
criteria: |
  PRIMARY: The ONE thing being tested. One sentence.
  AUTOMATIC FAIL (score 1): [specific observable failure condition]
  Score 2: [what "wrong" looks like — observable symptoms]
  Score 3: [what "partial" looks like — specific items present/absent]
  Score 4: [what "good" looks like — reserved for meeting all requirements]
  Score 5: [what "excellent" looks like — reserved for clear excellence, do NOT award by default]
```

**Anti-compression techniques:**
- Add "do NOT award by default" to score 5 description
- Add "most outputs that feel 'fine' belong here" to score 3
- Each level must describe observable differences, not degree words ("better", "more thorough")

## Rules

1. **One primary signal per eval.** Testing two things? Write two evals.
2. **Automatic-fail is mandatory.** Judges need a clear "wrong" signal.
3. **Countable over subjective.** "Mentions 3 of [list]" beats "thorough."
4. **Binary checks for orchestrator/multi-step skills.** Holistic criteria miss cross-step defects.
5. **Threshold matches panel health:** 3.0 for degraded (2-judge) panels, 3.5 for full (3+), 4.0 for correctness-critical.

## Orchestrator/Multi-Step Evals

Agent workflows that dispatch, route, and manage state need special criteria design:

- **Decompose by phase** — separate detection checks from action checks from methodology checks
- **Include trajectory markers** — "read file X" and "wrote to file Y" are observable tool calls
- **Name the expected classifications** — don't say "correctly classifies"; list WHAT should be classified HOW
- **State the fixture's ground truth** — judges can't verify against invisible expectations

## Activation Task Design

Negative tasks (`expect_activation: false`) must stay OUT of the skill's downstream territory. Use read-only/Q&A negatives for skills whose triggers overlap post-change workflow.

## Threshold Rationale

| Panel state | Recommended threshold | Why |
|-------------|----------------------|-----|
| Full (3+ judges, 2+ families) | 3.5-4.0 | Reliable signal |
| Degraded (2 judges) | 3.0 | Score variance too high for tight thresholds |
| Single judge | 2.5 (provisional only) | Cannot distinguish signal from bias |

Delta threshold (1.0) is more reliable than absolute threshold — less affected by panel size.

## Naming Convention

`{skill}-{verb}-{noun}` — e.g., `planning-cycles-produces-phases`, `code-review-checks-security`

## References

- For session transcript review patterns, read [references/session-review.md](references/session-review.md)
