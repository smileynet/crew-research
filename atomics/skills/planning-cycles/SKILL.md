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

Activate when: starting a new feature/epic, task feels too vague, scope unclear, multiple approaches exist.

Do NOT activate for: bug fixes, small well-defined tasks, tasks with clear specs.

## The Five Phases

```
Destination → Specify (anchor) → Brainstorm (diverge) → Sample (validate) → Scope (converge) → Finalize (commit)
```

### Destination (always first)

Before any phase: name what "done" looks like in one sentence. This fixes scope.

- "When this is done, [user can do X / system handles Y / we've proven Z]"
- If you can't state the destination, you need `/grill-with-docs` first, not planning

### Phase 0: Specify
- Describe the desired experience in the USER'S language (not implementation language)
- Format: "When [user does X], they [see/get Y]"
- 3-7 statements that define success from outside the system
- **Output:** specify document (user-facing acceptance criteria)
- **Gate:** user must approve before Phase 1 begins
- **Skip when:** user already provided clear acceptance criteria

**Phase 0 is mandatory for new features.** Your first output MUST be specify statements. If your instinct is to discuss architecture, STOP — write "When [user]..." statements first. Do NOT produce technical content before Phase 0 is complete.

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

### Phase 2b: Prototype (optional)
- Build throwaway code to answer a specific design question
- Route: logic question → TUI state explorer; visual question → multi-variant UI
- See [prototype-protocol](../prototype-protocol/SKILL.md) for full workflow
- **Output:** answer to the question (captured in commit/ADR/notes), prototype deleted
- **Use when:** "I'm not sure this state model works" or "I need to see options before committing"
- **Skip when:** question can be answered by reasoning alone, or requirements are already validated

### Phase 3: Scope
- Structure work into hierarchy (epic → feature → task)
- Add dependencies, priorities, acceptance criteria
- Identify **fog** — decisions you know are coming but can't specify yet. Don't fake-plan these; note them explicitly.
- **Output:** structured plan (YAML or markdown) + fog list (what remains unclear)
- **Review before proceeding**

### Phase 4: Finalize
- Convert plan to tracked work items (or PRD for larger features)
- Set up dependencies, identify first actionable task
- **Output:** tracked issues OR PRD (problem, solution, user stories, implementation decisions, testing decisions, out of scope)

## Rules

- **Pause between phases** — stop after each for review. Never flow brainstorm→finalize without user seeing artifacts.
- **Match depth to complexity** — epic (all phases), feature (1+3 minimum), task (3 only or skip).
- **Acceptance criteria are testable** — "works correctly" fails; "returns 200 with paginated results" passes.
- **Plans are editable** — propose, don't prescribe.
- **Don't over-plan** — no 4-phase cycle for a bug fix.
- **Brainstorm must converge** — ends with a recommended direction, not open exploration.
- **Don't skip Sample for user-facing work** — if it has a UI, walk through it.

## Phase Selection Quick Reference

| Situation | Run Phases |
|-----------|-----------|
| New feature, unclear requirements | 0 → 1 → 2 → 3 → 4 |
| Clear requirements, user-facing | 2 → 3 → 4 |
| Clear requirements, backend-only | 3 → 4 |
| Uncertain data model or state machine | 0 → 1 → 2b → 3 → 4 |
| UI direction unclear | 0 → 2 → 2b → 3 → 4 |
| Bug fix or small task | Skip (just do it) |
| Exploring a new domain | 1 only |
| Refactoring | 3 → 4 |
| Large feature needing PRD | 0 → 1 → 2 → 3 → 4 (PRD output) |
| Full PoC (new system/integration) | Use [poc-workflow](../poc-workflow/SKILL.md) instead |

## References

- Source practice: `docs/practices/planning-cycles.md` (in best_practices repo)
- Origin: line-cook/docs/cycles/mise-cycle.md
- Related: [prototype-protocol](../prototype-protocol/SKILL.md) for Phase 2b
- Related: [architecture-deepening](../architecture-deepening/SKILL.md) for refactoring plans

## Spike vs Tracer Bullet vs Prototype

Three tools for reducing uncertainty — pick based on what's unknown:

| Tool | Answers | Code fate |
|------|---------|-----------|
| **Spike** | "Is this feasible?" | Thrown away |
| **Prototype** | "Does this design feel right?" | Thrown away |
| **Tracer bullet** | "Does this path work end-to-end?" | Kept (production) |

**Quick decision**: Unknown feasibility → spike. Unknown design → prototype. Known what, unknown path → tracer bullet. Everything clear → just build it.

See [references/spike-tracer-prototype.md](references/spike-tracer-prototype.md) for the full decision framework.
