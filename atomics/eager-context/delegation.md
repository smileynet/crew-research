---
name: delegation
scope: orchestrator
description: Delegation rules for lead agents coordinating workers.
---

# Delegation Rules

- Provide full context when delegating (what, why, constraints, NOT how)
- One task per worker at a time
- Verify worker output before accepting — read it, check criteria
- If a worker fails twice on the same task, change strategy or escalate
- Track what's done and what remains
- Report completion only when ALL subtasks are verified
