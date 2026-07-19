# Grill Session — Open Questions for Tickets

**Started:** 2026-07-19
**Scope:** Unresolved design questions across open tickets (23, 27, 28, 29, 31, 34, 35; blocked: 30, 32, 33)
**Method:** Self-answer gate applied — questions the tickets/codebase already answer are excluded (see Pre-resolved below).

## Pre-resolved (codebase/tickets answer these — not asked)

| Question | Answer | Source |
|----------|--------|--------|
| Do SKIPs count in pass/fail tallies? | No — excluded, reported with reason; SKIP ≠ completed for `--skip-completed` | ticket 29 text (user-approved) |
| SKIP vs FAIL for missing adapters | SKIP-with-reason, never silent, never fail | extension-protocol precedent, ticket 29 |
| Deferred ledger location | `docs/development/deferred-runs.md` (committed; results/ is gitignored) | ticket 29 |
| Ticket 23 target adjustment | >50% is a stated guess; adjust with justification when window closes ~07-25 | handoff + ticket 23 |
| Ticket 27 replacement negatives | pure Q&A / read-only tasks, spelled out in AC | ticket 27 |
| Full-run abort when the AGENT adapter itself has no access | abort early with message (a suite of 100% SKIPs is pointless) | obvious from ticket 29 probe design |

## Questions

| # | Question | Status | Decision |
|---|----------|--------|----------|
| Q1 | Which machines have which tool/model access (crush, agy)? | RESOLVED → [Q01](Q01-access-map.md) | corp: no agy (POLICY — removed + ticket 36), crush via Bedrock/Claude-only (ticket 31); personal: full. CREW_ENV flag in .mise.local.toml; env: frontmatter on all tickets |
| Q2 | Per-env deploy sets in docs/commands | folded into Q1 → ticket 36 AC (corp: kiro-cli+codex; personal adds agy+crush) | — |
| Q3 | Ticket 34 cadence + proposal artifact format | pending | — |
| Q4 | Ticket 35 judge-swap bar + candidate constraints | pending | — |
| Q5 | skill-authoring invocation-model checkpoint (pending from probe) | pending | — |
