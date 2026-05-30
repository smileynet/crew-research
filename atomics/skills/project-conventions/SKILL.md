---
name: project-conventions
description: "Workspace behavioral rules enforced every turn."
metadata:
  type: reference
  invocation: agent-only
---

# Project Conventions (Always Enforce)

## Glossary Maintenance

Update `.memory/CONTEXT.md` immediately when a term is resolved or clarified. Don't batch — capture as it happens.

**Format:**
```
**Term**:
One-sentence definition.
_Avoid_: what not to call it
```

**What qualifies as a term:**
- Domain concepts (what the project calls things)
- Internal naming decisions (why we say X not Y)
- Abbreviations and acronyms in the codebase
- Anything where two people might use different words for the same thing

**What doesn't belong:** implementation details, specs, decisions with rationale (those are ADRs).

If CONTEXT.md doesn't exist, create it on first term resolution.

## Document Placement
- Default new documents to `.scratch/` (ephemeral)
- Only place in `.memory/` if a future session will need it
- Only place in `docs/` when explicitly requested for user-facing publication
- Never accumulate scratch — promote or delete

## Session Discipline
- Read before writing — check existing code/docs before creating new ones
- Commit after each logical unit of work
- Don't ask questions the codebase can answer — explore first
