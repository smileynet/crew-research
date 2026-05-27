# Spike vs Tracer Bullet vs Prototype

Three tools for reducing uncertainty. Pick based on **what you're uncertain about**.

## Comparison

| Tool | Question it answers | Code fate | Time-box |
|------|-------------------|-----------|----------|
| **Spike** | "Is this even feasible?" | Thrown away (learnings kept) | Hours–1 day |
| **Prototype** | "Does this design feel right?" | Thrown away (answer kept) | 1–3 days |
| **Tracer bullet** | "Does this path work end-to-end?" | Kept (production code, minimal) | 1–2 days |

## Decision Heuristic

```
Is the path through all layers unclear?
  YES → Can you build a thin slice with production quality?
    YES → Tracer bullet (keep the code)
    NO  → Too much unknown → Spike first, then tracer
  NO → Is the design/UX/state model unclear?
    YES → Prototype (throwaway, answer the question)
    NO  → Just build it
```

## When to Spike

- Evaluating a new technology/library/framework
- Testing whether a performance target is achievable
- Validating an integration works before designing around it
- Answering "can we?" not "how should we?"
- **Output**: findings doc, pass/fail verdict, ADR if decision is load-bearing
- **Process**: hypothesis → pass/fail criteria → minimal proof → measure → decide
- **Rules**: one hypothesis per spike, time-box to 1 day, no production polish

## When to Tracer Bullet

- Feature touches >2 files or >1 layer
- You know WHAT to build but need to prove the path works
- Production code from day one — minimal but real
- **Output**: working end-to-end slice (hardcoded values, single case, no edge cases)
- **Criteria**: "Can I invoke the feature end-to-end and see a result?"
- **Key difference from prototype**: tracer code is KEPT. It becomes the skeleton for the full feature.

## When to Prototype

- "Does this state machine handle edge case X?"
- "What should this look like?" (need to see options)
- You need to FEEL the design, not just reason about it
- **Output**: answer to the question (captured), code deleted
- See [prototype-protocol](../../prototype-protocol/SKILL.md) for full workflow

## Common Sequences

| Situation | Sequence |
|-----------|----------|
| New tech + new feature | Spike → Tracer → Build |
| Known tech, complex feature | Tracer → Build |
| UX-heavy feature | Prototype → Tracer → Build |
| Simple feature, known path | Just build it |
| "Can we even do X?" | Spike (may kill the idea) |
| Full PoC (new system) | Research → Spike → Design → Plan → Build → Validate |

For full PoC workflows, see [poc-workflow](../../poc-workflow/SKILL.md) which orchestrates the complete lifecycle.

## Anti-Patterns

- **Spike that becomes production code** — spikes are disposable. If you want to keep it, you needed a tracer.
- **Tracer that never gets filled in** — a tracer is Phase 1, not the whole feature. Plan Phase 2 before starting.
- **Prototype that ships** — prototypes have no tests, no error handling. Rewrite when adopting.
- **Skipping the spike when feasibility is genuinely unknown** — building a tracer on an unproven foundation wastes the production-quality effort.
