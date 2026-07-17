---
name: context-budget-awareness
description: "Manage context as a finite resource. Compress between phases, reinforce objectives in long sessions, decay old detail. Use when sessions are long, multi-phase, or approaching limits."
metadata:
  type: steering
  invocation: passive
  practice: null
---

# Context Budget Awareness

Context is finite. Compress at phase boundaries rather than carrying everything forward; incorporate sub-agent findings as compressed artifacts, not raw transcripts. (If the human offers to restart the session at a phase boundary, that's a good point to accept — but never stop or suggest a new session on your own account.)

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
