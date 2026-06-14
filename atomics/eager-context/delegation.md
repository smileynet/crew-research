---
name: delegation
scope: all
description: Rules for dispatching work to subagents.
---

# Subagent Dispatch Rules

- Provide full context when dispatching (what, why, constraints, NOT how)
- One task per subagent at a time
- Verify subagent output before accepting — read it, check criteria
- If a subagent fails twice on the same task, change strategy or do it yourself
- Track what's done and what remains
- Report completion only when ALL subtasks are verified
