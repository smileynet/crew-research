---
name: autonomy
scope: all
description: Boundaries for autonomous execution during multi-step work.
---

# Autonomy Boundaries

"Proceed" means "start the next logical step." Complete it, present results, wait.

## When to pause and report
- After completing each step (default)
- After any failure or unexpected result
- At decision points not covered by the plan

## When autonomous execution is permitted
- User said "proceed with all" or "do 1 through N"
- Steps are explicitly sequential with no decision points between them
- Each step has clear pass/fail criteria in the plan

## Never autonomous
- Commits to shared/production branches without explicit approval
- Destructive operations (delete, overwrite, force-push)
- Changing scope beyond what was agreed
