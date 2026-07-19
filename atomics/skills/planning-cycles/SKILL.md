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
- **Mandatory for new features.** Your first output MUST be specify statements. If your instinct is to discuss architecture, STOP — write "When [user]..." statements first. No technical content before Phase 0 completes.
- Describe the desired experience in the USER'S language: "When [user does X], they [see/get Y]" — 3-7 statements defining success from outside the system
- **Output:** specify document (user-facing acceptance criteria)
- **Gate:** user must approve before Phase 1 begins
- **Skip when:** user already provided clear acceptance criteria

### Phase 1: Brainstorm
- Ask clarifying questions; explore approaches in the codebase; identify risks and unknowns; recommend a direction with rationale
- **Output:** brainstorm document
- **Skip when:** requirements already clear

### Phase 2: Sample
- Walk through user experience (5 beats: first encounter, discovery, core workflow, edge cases, return); create interaction sketches; flag UX problems before they become tasks
- **Output:** walkthrough document
- **Skip when:** backend-only, UX already documented

### Phase 2b: Prototype (optional)
- Build throwaway code to answer a specific design question ("I'm not sure this state model works", "I need to see options"). Route: logic question → TUI state explorer; visual question → multi-variant UI. Full workflow: [prototype-protocol](../prototype-protocol/SKILL.md).
- **Output:** answer to the question (captured in commit/ADR/notes), prototype deleted
- **Skip when:** question answerable by reasoning alone, or requirements already validated

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
- **Competing forces without a clear winner?** → If archwright skills are available, recommend `archwright-resolve` — explicit tension resolution beats implicit compromise.

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

- Reasoning technique selection: [references/reasoning-modes.md](references/reasoning-modes.md)
- Assumption surfacing and tracking: [references/assumptions.md](references/assumptions.md)
- Related: [prototype-protocol](../prototype-protocol/SKILL.md) (Phase 2b), [architecture-deepening](../architecture-deepening/SKILL.md) (refactoring plans)

## Spike vs Tracer Bullet vs Prototype

Three uncertainty-reduction tools: unknown feasibility → **spike** (thrown away); unknown design → **prototype** (thrown away); known what, unknown path → **tracer bullet** (kept as production code). Everything clear → just build it. Full decision framework: [references/spike-tracer-prototype.md](references/spike-tracer-prototype.md).
