---
name: poc-workflow
description: "End-to-end PoC development workflow. Navigates from a loose idea to a validated proof through progressive discovery. Use when building a proof of concept, validating a new system design, or proving a pattern works before committing to production. Trigger: build a PoC, prove this works, validate this approach, prototype end-to-end."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# PoC Workflow

Navigate from a loose idea to a validated proof. The way isn't visible yet — discover it progressively, resolving one decision at a time until the path is clear enough to build.

## The Destination

Name what "done" looks like BEFORE planning. The destination fixes scope — everything else follows from it.

```markdown
## Destination
<What reaching the end of this PoC looks like — the working system,
validated hypothesis, or proven pattern. One or two lines.>
```

Examples:
- "A working pipeline that ingests 10K events/sec into ClickHouse with < 5s query latency"
- "Proof that the state machine handles all edge cases from the grill session"
- "End-to-end auth flow with SSO working against our IdP"

## The Map

The PoC map is `proposal-plan.md` at the root — a living index that tracks:

```markdown
## Destination
<one-line target>

## Decisions so far
- [Decision title] — one-line gist (detail in .memory/decisions.md)

## Active work
- [ ] Current spike/task and what it resolves

## Fog (not yet specified)
- Suspected decisions we'll hit but can't ticket yet

## Out of scope
- What this PoC explicitly does NOT prove
```

The map is an **index, not a store**. Decisions live in `.memory/decisions.md`. Research lives in `.memory/research-synthesis.md`. The map points, it doesn't restate.

## Progressive Discovery

Don't plan everything upfront. Resolve what's visible, then see what's next.

```
Name destination → Chart first frontier → Resolve one decision →
New frontier visible → Resolve next → ... → Way is clear → Build
```

Each resolved decision **clears fog** — making the next decisions visible. Stop charting when the way to the destination is clear enough to implement.

## Work Types

| Type | Purpose | Output |
|------|---------|--------|
| **Research** | Gather knowledge from docs, APIs, prior art | `.memory/research-synthesis.md` |
| **Spike** | Prove feasibility with throwaway code | `.memory/spike-N-findings.md` |
| **Grill** | Resolve design decisions via interrogation | `.memory/grill/{topic}/` |
| **Task** | Unblock a decision (provisioning, setup, access) | Checklist completed |

### Ordering principle

1. **Longest lead-time first** — kick off registrations, provisioning on day 1
2. **Spikes before build** — validate assumptions with throwaway code
3. **Research feeds grills** — don't grill blind; research the options first

## Phases

### Phase 0: Chart the map
Name destination → identify first frontier → note fog + out-of-scope → write `proposal-plan.md`.

### Phase 1: Research + Resolve
For each frontier item: research, grill, or spike. After each resolution: update the map (what cleared? what's newly visible?).

### Phase 2: Plan the build
When fog is clear: architecture diagram, task graph (spike → build → validate), component specs, acceptance criteria.

### Phase 3: Implement
Execute sequentially. Validate against plan after each component. Failure twice → new approach + document finding. Commit after each logical unit.

### Phase 4: Validate
End-to-end run. Check every acceptance criterion. Document gaps between plan and reality.

## Validation Checkpoint

Use at any phase transition:

1. Re-read current map
2. Compare built vs planned (table: Item | Done? | Issue)
3. Fix misalignments
4. Update map with new fog/frontier
5. Continue

## Rules

- **Name the destination first** — it fixes scope for everything else
- **Don't plan what you can't see** — fog is legitimate; chart only the visible frontier
- **One decision at a time** — resolve, update map, then pick the next
- **Spikes are throwaway** — keep findings, delete code
- **Plan is living** — update as fog clears
- **Don't ask, discover** — if codebase or API can answer, explore instead of asking
- **Don't over-engineer** — prove the pattern, not production-ready

## File Organization

See [references/poc-file-layout.md](references/poc-file-layout.md) for full layout.
