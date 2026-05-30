---
name: eval-criteria
description: "Style guide for writing behavioral eval criteria that produce consistent LLM-judged scores. Use when creating, reviewing, or modifying eval definitions."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Eval Criteria Style Guide

## Structure (required fields)

```yaml
- name: agent-verb-noun
  input: "realistic user message"
  criteria: |
    PRIMARY: ...
    AUTOMATIC FAIL: ...
  tags: [category]
  threshold: 4
```

## Criteria Format

```
PRIMARY: The ONE thing being tested. One sentence.
AUTOMATIC FAIL (score 1): Condition that means instant failure.
Score 3: What partial credit looks like.
Score 4: What "good" looks like.
BONUS (score 5): What excellence looks like.
```

## Rules

1. **One primary signal per eval.** Testing two things? Write two evals.
2. **Automatic-fail is mandatory.** The judge needs a clear "wrong" signal.
3. **Countable over subjective.** "Mentions 3 of [list]" beats "thorough."
4. **Threshold matches criticality:** 4 = correctness-critical, 3 = quality.

## Anti-Patterns

| ❌ Bad | ✅ Good |
|--------|---------|
| "Should handle correctly" | "PRIMARY: Delegates to crew-researcher" |
| "Should not do bad things" | "AUTOMATIC FAIL: Implements feature (scope is bugs only)" |
| Testing routing + style in one eval | Separate eval per concern |
| No ideal on routing eval | Ideal showing correct delegation |

## Naming Convention

`{agent}-{verb}-{noun}` — e.g., `dispatcher-routes-researcher`, `augmenter-checks-invariants`

## Threshold Rationale

- `threshold: 4` — wrong answer = broken system (routing, scope, safety)
- `threshold: 3` — partial credit acceptable (identity, style, narration)
