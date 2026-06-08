---
name: spec-driven-development
description: "Plan projects using PLAN.md and per-feature spec files. Use when starting a new project, breaking a project into phases, writing specs for features, or when someone says 'let's plan this out' or 'write a spec'. Trigger: PLAN.md, spec, feature spec, project plan, phases, task graph, validation criteria."
metadata:
  type: process
  invocation: both
---

# Spec-Driven Development

Every project gets a PLAN.md and per-feature specs. Specs exist for every feature — even already-implemented ones — so there's a clear mental model of each feature's purpose.

## Process

1. **Assess complexity** (1-5) before deciding depth
2. **Clarify** — resolve ALL ambiguity. Block on vague language.
3. **Write PLAN.md** — intent, phases, task graph with dependencies
4. **Write specs** for current phase before implementing
5. **Implement against spec** — requirements are acceptance criteria
6. **Reconcile** — update spec to match what was actually built
7. **Validate** using spec's validation section

## Complexity Scoring

| Score | Depth | Example |
|-------|-------|---------|
| 1 | No spec | Fix typo, config |
| 2 | Inline in PLAN.md | Single-function change |
| 3 | Light spec (what + validation) | New endpoint |
| 4 | Full spec | Multi-component feature |
| 5 | Full spec + design doc | New system |

## Clarification Gate

Do NOT proceed if any requirement uses vague language ("appropriate", "as needed", "various"), has implicit assumptions, or references undefined terms. Stop and ask.

## PLAN.md

```markdown
# Project Name

## Intent
One paragraph: what and why.

## Phases
### Phase 1: [Name]
- Goal: what this achieves
- Features: list (link to .specs/ files)
- Validates: how we know it works

## Task Graph
- Phase 1 → Phase 2 (dependency reason)
- Feature A → Feature B (B uses A's output)
- Feature C [P] (parallelizable)
```

## Feature Specs (`.specs/{slug}.md`)

See [references/spec-template.md](references/spec-template.md) for full template.

Required sections: Status, What, Who/Why, Non-Goals, Requirements, Validation.
Optional: Unresolved Questions, Alternatives Considered.

## Lifecycle

```
Draft → Accepted → Implemented → Reconciled → Validated
```

- **Accepted**: no unresolved questions, approved to build
- **Implemented**: code written, tests pass
- **Reconciled**: spec updated if implementation diverged
- **Validated**: validation criteria confirmed passing

## Rules

- Assess complexity before choosing depth
- Clarification is a gate, not a suggestion
- Non-Goals section mandatory for complexity 3+
- Validation must be concrete — "it works" fails
- Reconcile after implementation — lying specs are worse than no specs
- `[P]` = parallelizable, `→` = dependency
