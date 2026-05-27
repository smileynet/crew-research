---
name: poc-workflow
description: >
  End-to-end PoC development workflow. Takes a problem from research through
  design, planning, implementation, and validation. Use when building a proof
  of concept, validating a new system design, or proving a pattern works
  before committing to production. Trigger: "build a PoC", "prove this works",
  "validate this approach end-to-end".
metadata:
  type: process
  invocation: user-only
  practice: null
---

# PoC Workflow

Guide through building a PoC using structured phases. Resolve obvious decisions autonomously; ask only when genuine ambiguity exists.

## Phases

```
Understand → Research → Design → Plan → Implement → Validate
```

### Phase 0: Understand
- Review background materials (conversations, requirements, prior research)
- Create **summary.md** (what happened, who's involved, key context)
- Create **requirements.md** (MVP scope, future scale, technical needs)
- Create **research-topics.md** (what to investigate before building)

### Phase 1: Research
- Dispatch parallel research per topic (web search + docs)
- Write raw findings to `.scratch/` (ephemeral)
- Synthesize into **research-synthesis.md**: findings, recommended approach, gaps, recommended spikes

### Phase 2: Design
- Interrogate the plan one question at a time (grill pattern)
- Research each question before presenting 2-3 options with pro/con
- State recommendation, wait for input
- Resolve obvious decisions silently
- Capture all decisions to `.memory/decisions.md`

### Phase 3: Plan
- Architecture diagram + API contract
- Project structure + phased implementation (Spikes → Build → Validate)
- Component specs (behavior, error handling, config)
- Task graph with dependencies
- Cost estimate + production path (what comes after PoC)

### Phase 4: Implement
Execute in order: **Spikes first**, then Build.
- Execute tasks sequentially, marking complete
- After each component: validate against plan, document deltas
- On failure: fix forward. If approach fails twice → different approach + document finding
- Commit after each logical unit

### Phase 5: Validate
- Run full system end-to-end
- Check every acceptance criterion from plan
- Document findings in `.memory/`
- Note gaps between plan and reality

## Validation Checkpoint

Use at any point during implementation:

1. Re-read current plan
2. Compare built vs specified (table: Plan Item | Implemented? | Issue)
3. Fix misalignments
4. Document findings that impact future work
5. Update plan, continue

## Rules

- **Spikes first** — validate assumptions before building
- **Longest lead-time first** — kick off registrations, provisioning, approvals on day 1
- **Plan is living** — update as findings emerge
- **Don't ask, discover** — if codebase or API can answer, do that instead of asking
- **Commit after each logical unit** — descriptive conventional commits
- **Don't over-engineer** — prove the pattern, not production-ready

## File Organization

See [references/poc-file-layout.md](references/poc-file-layout.md) for full layout.

Key placement: decisions → `.memory/decisions.md`, raw research → `.scratch/`, hard-to-reverse decisions → `docs/adr/`, implementation plan → `proposal-plan.md` (root).
