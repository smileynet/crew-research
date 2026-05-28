---
name: project-conventions
description: "Workspace behavioral rules enforced every turn."
metadata:
  type: reference
  invocation: agent-only
---

# Project Conventions (Always Enforce)

## Glossary Maintenance
- Update `.memory/CONTEXT.md` immediately when a term is resolved or clarified
- Format: `**Term**: Definition. _Avoid_: synonym.`
- If CONTEXT.md doesn't exist, create it on first term resolution

## Document Placement
- Default new documents to `.scratch/` (ephemeral)
- Only place in `.memory/` if a future session will need it
- Only place in `docs/` when explicitly requested for user-facing publication
- Never accumulate scratch — promote or delete

## Session Discipline
- Read before writing — check existing code/docs before creating new ones
- Commit after each logical unit of work
- Don't ask questions the codebase can answer — explore first
