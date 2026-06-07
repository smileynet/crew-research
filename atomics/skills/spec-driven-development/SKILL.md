---
name: spec-driven-development
description: "Plan projects using PLAN.md and per-feature spec files. Use when starting a new project, breaking a project into phases, writing specs for features, or when someone says 'let's plan this out' or 'write a spec'. Trigger: PLAN.md, spec, feature spec, project plan, phases, task graph, validation criteria."
metadata:
  type: process
  invocation: both
---

# Spec-Driven Development

Every project gets a PLAN.md and per-feature specs. Specs exist for every feature — even already-implemented ones — so there's a clear mental model of each feature's purpose.

## Artifacts

### PLAN.md (project root)

High-level intent and structure:

```markdown
# Project Name

## Intent
One paragraph: what we're building and why.

## Phases

### Phase 1: [Name]
- Goal: what this phase achieves
- Features: list of features (link to specs)
- Validates: how we know this phase works

### Phase 2: [Name]
...

## Task Graph
- Phase 1 → Phase 2 (Phase 2 depends on Phase 1 infra)
- Feature A → Feature B (B uses A's API)
- Feature C (independent, can parallelize)
```

### Feature Specs (`.specs/` or `docs/specs/`)

One file per feature or phase. Name: `{feature-slug}.md`

```markdown
# Feature: [Name]

## What
One paragraph: what this feature does.

## Who / Why
Who uses it, what problem it solves for them.

## Requirements
- [ ] Functional requirement 1
- [ ] Functional requirement 2
- [ ] Non-functional (performance, security, etc.)

## Validation
How we prove it works:
- **Blackbox**: input X → expect output Y
- **Visual/Image**: screenshot comparison, UI state check
- **Real-world**: user workflow end-to-end test
- **Automated**: test commands that pass/fail

## Status
Draft | In Progress | Implemented | Validated
```

## Process

1. **Write PLAN.md first** — intent, phases, task graph
2. **Write specs for Phase 1 features** before implementing
3. **Implement against the spec** — requirements are acceptance criteria
4. **Validate using spec's validation section** — don't mark done until validated
5. **Write specs for next phase** as current phase stabilizes
6. **Backfill specs for existing features** — captures what's already built so the team shares a mental model

## Rules

- Every feature gets a spec, even if it's already implemented
- Spec comes before implementation (unless backfilling)
- Validation section must be concrete — "it works" is not a validation plan
- PLAN.md stays high-level — detail lives in specs
- Task graph shows dependencies, not schedule
- Phases are delivery increments, not calendar sprints
