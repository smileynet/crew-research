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
5. **Self-review** — run quality gates on your own spec before presenting
6. **Implement against spec** — requirements are acceptance criteria
7. **Reconcile** — update spec to match what was actually built
8. **Validate** using spec's validation section

## Complexity Scoring

| Score | Depth | Example |
|-------|-------|---------|
| 1 | No spec | Fix typo, config |
| 2 | Inline in PLAN.md | Single-function change |
| 3 | Light spec (what + validation) | New endpoint |
| 4 | Full spec | Multi-component feature |
| 5 | Full spec + design doc | New system |

## Clarification Gate

When the user's request contains vague language, DO NOT write a spec. Instead:
1. List every vague/ambiguous term found
2. Propose concrete alternatives for each
3. Ask the user to confirm before proceeding

Blocked terms: "appropriate", "as needed", "various", "properly", "efficiently", "user-friendly", "fast enough", "etc.", "handle X somehow"

## Self-Review Gates (run before presenting spec)

After drafting, silently check before showing the user:

- **Scope**: Does "What" use "and" to connect 3+ distinct capabilities? → Split.
- **Non-Goals**: Is it empty for complexity 3+? → Add 3-5 boundaries.
- **Validation**: Could someone run these checks without asking me questions? If no → rewrite as concrete input→output.
- **Testability**: Replace any criterion containing "correctly", "properly", "timely", "responsive" with a measurable target.

Do not present a spec that fails these. Fix it first.

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

## Rules

- Clarification is a gate — vague input = ask, don't assume
- Self-review before presenting — never show a spec with vague validation
- Non-Goals mandatory for complexity 3+
- Reconcile after implementation — lying specs are worse than no specs
- `[P]` = parallelizable, `→` = dependency
