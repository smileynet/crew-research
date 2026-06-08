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

```markdown
# Project Name

## Intent
One paragraph: what we're building and why.

## Phases

### Phase 1: [Name]
- Goal: what this phase achieves
- Features: list (link to spec files)
- Validates: how we know this phase works

## Task Graph
- Phase 1 → Phase 2 (dependency reason)
- Feature A → Feature B (B uses A's output)
- Feature C [P] (parallelizable)
```

`[P]` marks tasks that can run in parallel with siblings.

### Feature Specs (`.specs/{feature-slug}.md`)

```markdown
# Feature: [Name]

## Status
Draft | In Review | Accepted | Implemented | Validated

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
- **Visual**: screenshot comparison, UI state check
- **Real-world**: user workflow end-to-end
- **Automated**: test commands that pass/fail

## Unresolved Questions
- Open question that needs answering before/during implementation

## Alternatives Considered
- Option B: why we didn't choose it
```

## Process

1. **Clarify** — resolve ambiguity before writing. Ask "what's unclear?"
2. **Write PLAN.md** — intent, phases, task graph
3. **Write specs for Phase 1** before implementing
4. **Implement against spec** — requirements are acceptance criteria
5. **Validate using spec's validation section** — don't mark done until validated
6. **Advance spec status** — Draft → Accepted → Implemented → Validated
7. **Backfill specs for existing features** — captures what's already built

## Scale-Adaptive Depth

| Change size | What to write |
|-------------|---------------|
| Bug fix / small tweak | Nothing (just fix it) |
| Single feature | One spec file |
| Multi-feature phase | PLAN.md + spec per feature |
| New project | PLAN.md + phase specs + feature specs |

## Rules

- Spec comes before implementation (unless backfilling)
- Validation section must be concrete — "it works" is not a plan
- PLAN.md stays high-level — detail lives in specs
- Task graph shows dependencies, not schedule
- Unresolved questions must be answered before implementation starts
- Keep specs updated as requirements change during implementation
