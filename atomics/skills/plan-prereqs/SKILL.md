---
name: plan-prereqs
description: "Identify research, spikes, and tooling needed before implementing a plan. Use after planning to enumerate pre-work and ordering."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Plan Prerequisites

Read the current plan (proposal-plan.md, docs/plan.md, or ask which document). For each item, identify what must be true BEFORE implementation can start.

## Output

### Research Topics
What we need to learn. For each:
- **Topic**: specific question to answer
- **Blocks**: what can't start without this answer
- **Method**: web search, codebase exploration, docs review, or ask stakeholder

### Spikes
What we need to prove. For each:
- **Hypothesis**: "We can do X within constraint Y"
- **Pass/fail criteria**: specific, measurable
- **Time-box**: hours (not days)
- **Unblocks**: what implementation work depends on this

### Tools & Scripts
What we need to build first. For each:
- **What**: what it does
- **Why**: why main implementation depends on it
- **Effort**: rough estimate

### Ordering
- Dependency graph: what must complete before what else can start
- Critical path: the longest chain
- Parallel tracks: what can run simultaneously
- Longest lead-time items flagged (registrations, provisioning, approvals)

## Rules

- Only list pre-work that BLOCKS implementation — not nice-to-haves
- Spikes answer "can we?" — if the answer is obvious, skip it
- Research answers "how should we?" — if the approach is clear, skip it
- Tools are pre-work only if main implementation depends on them
- If nothing blocks: say so and recommend starting immediately
- Output feeds into `/ticket-planning` — research topics and spikes become ticket prereqs
