---
kind: pattern
id: git-native-claim
name: "Git-Native Claim: Allocation and Announcement Are One Push"
scale: loops-systems
confidence: "★"
status: active
serves: [pf-concurrent-sessions-safe]
context: []
completed_by: [surgical-git-side-effects]
resolves_into:
  - "behavior:claim-allocation-loop"
  - "constraint:allocation-single-step"
---

# Git-Native Claim: Allocation and Announcement Are One Push

## Problem

**Concurrent sessions allocate ticket ids and start work with no arbiter except eventually-pushed files, so two sessions can mint the same id or do the same work.**

## Context

The root coordination pattern for tkt. `surgical-git-side-effects` completes it at the single-operation scale.

## Forces

- **Desire:** An operator running concurrent agent sessions wants each session to claim work without colliding with another's (pf-concurrent-sessions-safe).
- **Constraint (hard):** Git fetch/commit/push is the only coordination medium — no server, lock, or database (git-coordination-medium).
- **Constraint (hard):** Allocation must be race-free and indivisible from its announcement (allocation-race-free).
- **Constraint (hard):** Sequential human-readable ids are load-bearing for prose cross-references and selection order (sequential-readable-ids).
- **Constraint (soft):** WIP must be visible in pushed ticket state, not only commit messages (wip-visible).

## Evidence

- Empirical: 5 collision incidents across two repos in 3 days — crew 12/13 (a03798e), crew 37↔39 (b28449f), archwright 005 double-implementation (reconciliation merge 06d74a2), archwright 009/010 (renumber 0806851). One occurred AFTER the manual claim protocol existed, proving prose protocol (Level 4 enforcement) insufficient (ticket 38 Resolution, 2026-07-20).
- Rejected alternative — random ids: tk (trialed 2026-07-19) sidesteps the race with `t-` + 4-char nanoid, but random ids break sequential cross-references and lowest-number-first selection (`.scratch/research/tk-capabilities.md` §3).
- Rejected alternative — steering-only: enforcement-hierarchy skill classifies mechanical rules as Level 2 (automation); the post-protocol collision is the direct counterexample to Level 4 sufficiency.
- Mechanism: optimistic concurrency needs an authoritative serialization point; in a git-only world the remote's ref update IS that point — a push that lands is an accepted claim, a rejected push is a lost race, detectable immediately and cheap to retry while the ticket is seconds old (operator decision D1a, resolve 2026-07-20).
- Prior art (2026-07-20 research, `.scratch/research/prior-art-git-coordination.md`): the CAS mechanism is well-attested — git ref updates are atomic compare-and-set (SO 2013 git locking; force-with-lease semantics 2018), and Apache Iceberg's commit protocol (2026) uses the identical OCC-pointer-swap-losers-retry shape. The COMPOSITE (sequential ids via push-retry) has no direct prior art: Fossil (~2010), git-bug (2018), git-appraise (2017), and Beads (2025) all chose hash ids when they hit this problem. **Scope boundary, not refutation:** those tools target offline/multi-remote operation where no serialization point exists; this pattern assumes ONE authoritative remote — exactly the condition under which Fossil's "not possible" claim doesn't apply. Beads' sequential→hash migration after multi-agent collisions is the watch signal: if offline creation or fork-based tickets ever enter scope, revisit this resolution.

## Therefore

**One command owns mint-to-announce.** `tkt new` performs fetch → true-max id scan across local AND origin `.tickets/` → create file → commit → push as a single operation. The push is the claim: if it is rejected, the tool re-fetches, re-allocates the next id, and retries (bounded, 3 attempts), reporting any renumber. `tkt claim <id>` marks WIP by setting `status: in_progress` and pushing, so other sessions see claimed work in file state, not just history.

## Consequences

- The tool must run inside the target repo's git context with a reachable remote; offline allocation is unsupported (accepted cost).
- Introduces `in_progress` into the status vocabulary — frontier computation must exclude it while boards must show it.
- Retry-renumber means an id proposed to the user may change at claim time; the tool must report the final id loudly.
- Does NOT cover: work-claim contention on an EXISTING ticket (two sessions claiming the same open ticket — mitigated, not eliminated, by in_progress visibility), or repos with no remote.

## Verification

- Behavior spec `claim-allocation-loop`: allocation FSM with push-rejected → re-allocate transition, bounded retries.
- Constraint spec `allocation-single-step`: tkt source performs fetch and push within the `new` command path (no allocation without announcement).
- Acceptance test (ticket 40 AC): allocation past origin's max when local is stale.

## Completion

This pattern is incomplete unless it also contains:
- `surgical-git-side-effects` — what exactly the claim commit may touch.
