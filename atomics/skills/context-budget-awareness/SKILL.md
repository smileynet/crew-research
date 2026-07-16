---
name: context-budget-awareness
description: "Manage context as a finite resource. Compress between phases, reinforce objectives in long sessions, restart before degradation. Use when sessions are long, multi-phase, or approaching limits."
metadata:
  type: steering
  invocation: passive
  practice: null
---

# Context Budget Awareness

Context is finite and depletable. Fresh context produces better results than accumulated context.

## When to Restart

- **Phase transitions** — start fresh for each major phase (research → plan → implement)
- **Quality degradation** — repeating yourself, contradicting prior statements, losing the objective
- **After sub-agent returns** — incorporate findings as compressed artifacts, not raw transcripts

## Decaying Resolution

When compressing prior work, preserve decisions and drop mechanics:

| Age | Keep | Drop |
|-----|------|------|
| Current phase | Full detail (files, diffs, decisions, blockers) | Nothing |
| Previous phase | Key outcomes + file paths + decisions | Exploration, intermediate reasoning, raw tool output |
| 2+ phases ago | One-line summary of what was decided | Everything else |

**Never compress:** decisions, constraints, acceptance criteria, file paths that are still relevant.

## Context Reinforcement

In long sessions (20+ messages), the model loses track of original objectives.

- Re-state the current objective after sub-agent returns or phase transitions
- After errors or retries, re-state constraints that were violated
- After 5+ tool calls without progress, pause and re-anchor: "We're doing X. Status is Y. Next is Z."

## Anti-Patterns

- Carrying raw research into implementation (summarize first)
- Accumulating verbose tool output without extracting the relevant result
- Assuming constraints stated 30+ messages ago are still active in attention
- Running multi-phase work in a single unbroken context when phases are independent
