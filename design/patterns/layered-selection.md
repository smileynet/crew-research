---
kind: pattern
id: layered-selection
name: "Layered Selection: Filter, Jump, Then Lowest Number"
scale: verbs-interactions
confidence: "★★"
status: active
serves: [pf-urgency-out-of-band, pf-env-policy]
context: [intersection-contract]
completed_by: []
resolves_into:
  - "behavior:frontier-selection"
---

# Layered Selection: Filter, Jump, Then Lowest Number

## Problem

**Next-work selection wants to stay trivially predictable, but urgency flags and machine policy both legitimately override it — and ad-hoc overrides make selection inscrutable.**

## Context

In the context of `intersection-contract`, this pattern addresses the one computation every session runs first: what to work on.

## Forces

- **Desire:** The operator flags urgent work out-of-band and every session's selection respects it (pf-urgency-out-of-band).
- **Desire:** Work is constrained to machines where it is permitted (pf-env-policy).
- **Constraint (hard):** Frontier excludes tickets whose env designation doesn't match the machine (env-filtered-frontier).
- **Constraint (hard):** `priority: high` overrides lowest-number-first (priority-jumps-order).

## Evidence

- Stated convention: frontier-work steering — "Pick the lowest-numbered frontier ticket — unless a frontier ticket carries priority: high frontmatter (user-flagged), which jumps the number order." Env gating stated in glossary (CREW_ENV) and grill Q01.
- Empirical gap: env gating was "half-mechanical — nothing filters frontier by CREW_ENV" (crew extraction §4); ticket 30 (`env: personal`) is manually excluded from every frontier statement in docs/plan.md — a repeated hand-computation this pattern mechanizes.
- Mechanism (why fixed precedence): filters and sorts compose predictably only when staged — exclusion (env) must precede ordering (priority, number) or a high-priority forbidden ticket would surface on the wrong machine. A single pipeline with fixed stages keeps "why did it pick that?" answerable in one sentence.
- Rejected alternative — scoring/weights: nothing in either repo needs ranked tradeoffs; a weight model would make selection inscrutable for zero expressive gain (minimal-contract force).
- Prior art (2026-07-20, `.scratch/research/prior-art-selection-decay.md`): strict-precedence-then-deterministic-tiebreak is established across scheduling theory (SPQ-vs-WRR literature 2010; layered-discipline scheduler patent 2006), queueing theory (static priority guarantees top-class service under overload, arXiv 2020), and kanban practice (explicit pull/eligibility criteria, scrum.org). Weighted-scoring rejection echoed by vulnerability-management critique ("a weighted score is a number; a decision record is evidence", 2026). Bounded contradiction: Kubernetes APF (KEP-1040) moved away from strict precedence because it starves low classes at scale — acceptable here because priority:high volume is operator-bounded with a human in the loop.

## Therefore

**A three-stage pipeline with fixed precedence.** Stage 1 ELIGIBILITY: status is `open` AND every `blocked_by` id is `done` AND (`env` absent OR matches $CREW_ENV OR is `either`). Stage 2 URGENCY: tickets with `priority: high` rank before all others. Stage 3 ORDER: ascending numeric id. `tkt ready` outputs this ordering; the PROPOSAL ("Next on the frontier: … Start?") remains steering behavior consuming the tool's output — computation Level 2, conversation Level 4.

## Consequences

- `in_progress` tickets are NOT frontier (claimed elsewhere) — boards must surface them separately or WIP goes invisible.
- Machines without $CREW_ENV set see the unfiltered frontier (env absent = either on both sides) — corp policy enforcement still requires the env var to be set (ticket 36's territory).
- Does NOT cover: lane-based partitioning between named parallel sessions (archwright prose concept — future extension field if ever tooled), or cross-repo frontiers.

## Verification

- Behavior spec `frontier-selection`: invariants over the pipeline (an env-excluded ticket never appears; a high-priority frontier ticket always ranks first; otherwise ascending ids).
- Acceptance test (ticket 40 AC): `tkt ready` matches the hand-rolled awk frontier on both repos' current tickets.

## Completion

This pattern is incomplete unless it also contains:
- Nothing further at this scale — selection is one verb over the contract.
