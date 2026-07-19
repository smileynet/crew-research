---
name: spec-driven-development
description: "Plan projects using PLAN.md and per-feature spec files. Use when starting a new project, breaking a project into phases, writing specs for features, or when someone says 'let's plan this out' or 'write a spec'. Trigger: PLAN.md, spec, feature spec, project plan, phases, task graph, validation criteria."
metadata:
  type: process
  invocation: both
  practice: null
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

When the user's request contains vague language, OUTPUT ONLY a clarification request. Do not include a draft, assumptions, or "meanwhile here's what I'd suggest." Questions OR spec, never both.

Blocked terms: "appropriate", "as needed", "various", "properly", "efficiently", "user-friendly", "fast enough", "etc.", "handle X somehow"

**Refusal format:**
```
## Cannot Write Spec Yet

These terms need definition before I can proceed:
- "fast" → What latency target? (e.g., <10ms p99, <100ms p50)
- "various" → Which specific formats? List them.

Once you clarify, I'll write the spec.
```

**Scope gate:** If requirements span 3+ independent capabilities, respond with a PLAN.md proposal showing decomposition — not a single monolithic spec.

## Self-Review Gates (run before presenting spec)

After drafting, silently check before showing the user:

- **Scope**: Does "What" use "and" to connect 3+ distinct capabilities? → Don't present. Propose decomposition instead.
- **Non-Goals**: Is it empty for complexity 3+? → Add 3-5 boundaries before presenting.
- **Validation**: Could someone run these checks without asking me questions? If no → rewrite as concrete input→output before presenting.
- **Testability**: Replace any criterion containing "correctly", "properly", "timely", "responsive" with a measurable target.

Never present a spec that fails these. Fix it silently, or if unfixable without user input, ask — but never show a flawed draft alongside the questions.

## PLAN.md

The plan is a living map, not a static document. Required sections: Destination (one sentence), Phases table, Decisions so far, Task Graph, Fog (not yet specified), Out of scope. Update PLAN.md after each resolved decision — fog graduates to phases when it sharpens.

Full template: [references/spec-template.md](references/spec-template.md).

## Feature Specs (`.specs/{slug}.md`)

See [references/spec-template.md](references/spec-template.md) for full template.

Required sections: Status, What, Who/Why, Non-Goals, Requirements, Validation.
Optional: Unresolved Questions, Alternatives Considered.

## Lifecycle

```
Draft → Accepted → Tickets Created → Implemented → Reconciled → Validated
```

After a spec is **Accepted**, decompose it into tickets using `/ticket-planning`. Tickets become the workable units; the spec remains the authoritative requirements doc.

## Rules

- Clarification is a gate — vague input = ask, don't assume
- Self-review before presenting — never show a spec with vague validation
- Non-Goals mandatory for complexity 3+
- Reconcile after implementation — lying specs are worse than no specs
- `[P]` = parallelizable, `→` = dependency
- Spec needs mechanical verification (invariants, state machines, constraint checks)? → If archwright skills are available, recommend its pipeline (`archwright-derive`/`-check`) for checkable specs

## References

- For reviewing/validating specs before implementation, read [references/review-checklist.md](references/review-checklist.md)
