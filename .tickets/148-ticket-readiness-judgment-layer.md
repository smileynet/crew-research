---
id: "148"
title: "Ticket readiness judgment layer in plan-ticket-sync + project-cleanup + handoff nudge"
status: open
blocked_by: []
---

# Ticket readiness judgment layer in plan-ticket-sync + project-cleanup + handoff nudge

## Context

Every existing mechanical check targets structural correctness (`tkt validate`: cycles,
dangling blocked_by, id↔filename) or the CLOSE event (`tkt audit`/`close`: unchecked ACs,
TBD resolution). **Nothing verifies an OPEN/frontier ticket has enough to START** — a spec
link, references to prior work, concrete testable ACs, sufficient context. That bar lives
only in Level-4 prose (tkt skill's ticket-standards.md), which the spec itself warns will
decay ("automate a field or drop it").

This is the JUDGMENT half of a layered pair. The MECHANICAL half is ticket B (tkt repo:
`tkt validate` frontier-readiness rule). Per enforcement-hierarchy, mechanical proves slots
are filled; judgment proves the fills are adequate — neither substitutes.

Prior art: this is a **Definition of Ready** (entry gate, mirror of Definition of Done) +
INVEST. Precedent for the mechanical side: Jira Field Required Validator, Linear LineGuard.

## What to build

1. **plan-ticket-sync** — add a readiness-sufficiency step (its row-maintenance duty is being
   removed by ticket 149, so this becomes its new core job): for each frontier ticket, judge
   — is the context sufficient to actually do the work; do references point to CURRENT work;
   are ACs testable-not-procedural? Report under-ready tickets; don't auto-fix.
2. **project-cleanup Phase 5** — add one readiness-sufficiency line to the ticket-sync phase.
3. **handoff** — one nudge line in Recommended Updates for under-specified frontier tickets.

Judgment-only (NOT mechanical — that's ticket B): ACs independently testable, context
SUFFICIENT to start, references point to the RIGHT/current artifacts, behavioral not
procedural.

## Eval obligation

**plan-ticket-sync has ZERO eval coverage** (verified: no active or retired def). Repurposing
its core job with no regression signal is a standing gap — ship with at least
`tools/evals/definitions/activation-plan-ticket-sync.yaml` (5 pos / 5 neg).

## References

- **`.memory/specs/ticket-plan-handoff-workstream.md` § Part 1** — readiness definition (WELL-FORMED
  vs READY-TO-START), layered mechanical/judgment enforcement, DoR/INVEST + Jira/Linear prior art (TRACKED source of truth)
- Relates to 149 (frees plan-ticket-sync's row-maintenance) and tkt#173 (the mechanical validate rule)

## Acceptance criteria

- [ ] plan-ticket-sync gains a readiness-sufficiency step (judgment, frontier-scoped, report-not-fix)
- [ ] project-cleanup Phase 5 + handoff Recommended-Updates each gain a readiness line
- [ ] `activation-plan-ticket-sync.yaml` created (closes the zero-coverage gap)
- [ ] `mise run validate` + lint pass; changes relocate/compress, never delete covered content
