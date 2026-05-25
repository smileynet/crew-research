---
metadata:
  type: protocol
  invocation: both
  practice: null
name: planning-cycles
description: Structure work through phased planning — brainstorm, validate, scope, finalize. Use when starting new features, breaking down epics, or when a task feels too vague to implement directly.
---

# Planning Cycles


Separate divergent thinking from convergent thinking. Validate before committing.

## Trigger Conditions

Activate when:
- Starting a new feature or epic
- Task feels too vague to implement directly
- User says "plan this", "how should we approach", "break this down"
- Scope is unclear or requirements are ambiguous
- Multiple approaches exist and none is obviously correct

Do NOT activate for: bug fixes, small well-defined tasks, tasks with clear specs already written.

## The Four Phases

```
Brainstorm (diverge) → Sample (validate) → Scope (converge) → Finalize (commit)
```

### Phase 1: Brainstorm
- Ask clarifying questions
- Explore approaches in the codebase
- Identify risks and unknowns
- Recommend direction with rationale
- **Output:** brainstorm document
- **Skip when:** requirements already clear

### Phase 2: Sample
- Walk through user experience (5 beats: first encounter, discovery, core workflow, edge cases, return)
- Create interaction sketches
- Flag UX problems before they become tasks
- **Output:** walkthrough document
- **Skip when:** backend-only, UX already documented

### Phase 3: Scope
- Structure work into hierarchy (epic → feature → task)
- Add dependencies, priorities, acceptance criteria
- **Output:** structured plan (YAML or markdown)
- **Review before proceeding**

### Phase 4: Finalize
- Convert plan to tracked work items
- Set up dependencies
- Identify first actionable task
- **Output:** tracked issues ready for execution

## Required Patterns

**Pause between phases.** MUST stop after each phase for review. Do not flow continuously from brainstorm to finalize without the user seeing intermediate artifacts.

**Match depth to complexity.** MUST select appropriate phases based on task size:
- Epic (3+ sessions): all 4 phases
- Feature (1-3 sessions): phases 1 + 3 minimum
- Task (single session): phase 3 only, or skip planning entirely

**Acceptance criteria are testable.** MUST write acceptance criteria that can be verified. "Works correctly" is not testable. "Returns 200 with paginated results when given valid auth token" is.

**Plans are editable.** MUST present plans as artifacts the user can modify. Propose, don't prescribe.

## Banned Patterns

**Over-planning small tasks.** MUST NOT run a full 4-phase cycle for a bug fix or config change.

**Brainstorming without converging.** MUST NOT explore endlessly. Brainstorm ends with a recommended direction.

**Skipping Sample for user-facing work.** SHOULD NOT skip Phase 2 when the output has a user interface (CLI, web, API with human consumers).

**Plans as immutable contracts.** SHOULD NOT treat finalized plans as unchangeable. Update as implementation reveals new information.

## Phase Selection Quick Reference

| Situation | Run Phases |
|-----------|-----------|
| New feature, unclear requirements | 1 → 2 → 3 → 4 |
| Clear requirements, user-facing | 2 → 3 → 4 |
| Clear requirements, backend-only | 3 → 4 |
| Bug fix or small task | Skip (just do it) |
| Exploring a new domain | 1 only |
| Refactoring | 3 → 4 |

## References

- Source practice: [`docs/practices/planning-cycles.md`](../../../docs/practices/planning-cycles.md)
- Origin: line-cook/docs/cycles/mise-cycle.md
