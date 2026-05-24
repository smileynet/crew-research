---
name: five-whys
description: >
  Iterative root cause analysis for non-obvious or recurring technical
  problems. Use when a failure keeps recurring, when the immediate cause
  isn't the real cause, when a fix didn't stick, or when someone asks
  "why does this keep happening." Not needed for problems where reading
  the code or error message directly reveals the answer.
metadata:
  type: reasoning-mode
  invocation: both
  practice: null
---

# Five Whys

Iterative causal chain — each answer becomes the input to the next question.

## Process

1. State the **symptom** clearly (what went wrong, observable evidence)
2. Ask **Why #1** — what is the immediate cause?
3. Take that answer and ask **Why #2** — why did THAT happen?
4. Continue chaining until you reach a **root cause** (something actionable)
5. Stop when the next "why" would leave your sphere of influence

## Rules

- Each why MUST build on the previous answer (single causal chain)
- Do NOT branch into parallel hypotheses (that's cause-mapping, not five-whys)
- Do NOT stop at the first why — surface causes are rarely root causes
- 5 is a guideline, not a rule — stop when you hit something actionable
- If the chain forks, pick the most likely branch and note alternatives

## Output Shape

```
Symptom: [observable problem]

Why 1: [immediate cause]
Why 2: [cause of the cause]
Why 3: [deeper cause]
Why 4: [structural/systemic cause]
Why 5: [root cause — actionable]

Root cause: [one sentence]
Action: [what to fix]
```

## When to Switch

- If multiple independent causes exist → use cause-mapping instead
- If the problem is "which option to pick" → use decision-matrix instead
- If you need to stress-test a plan → use pre-mortem instead
