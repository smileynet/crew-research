---
created_at: 2026-08-31T16:03:00-07:00
base_commit: f26dc81
handoff_key: ticket-plan-handoff-workstream
---

# Handoff

## Objective
Reduce ticket-workflow ceremony/drift: (148) enforce ticket readiness, (149) slim PLAN.md to
narrative + retire sync-plan tabular drift machinery, (150) restructure handoff to the in-flight
delta. All are DESIGNED + ticketed; none implemented yet. Companion tkt#173 (mechanical readiness).

## Constraints
- **No archwright pipeline needed** — the design is already resolved on disk: cite
  `design/patterns/automate-or-drop.md` (★★), `design/forces/ceremony-decays.md`,
  `design/forces/pf-plan-reflects-truth.md`. Direct edits.
- **`sync-plan` is a tkt CLI subcommand (D:/code/tkt)** — 149's retirement spans TWO repos; needs
  a tkt companion ticket for the CLI half.
- Windows eval env: use `tools/evals/scripts/run-eval-windows.py`, not the Linux harness.

## Prior Decisions
- PLAN.md: replace-with-lighter, NOT deprecate. Tabular layer (status/blocked_by/frontier) =
  redundant with tickets; narrative layer (campaign arc, ordering rationale) = keep. spec-driven-
  development survives untouched (uses PLAN.md as narrative map, not status table).
- Handoff: over-specified; collapse to Focus/In-Flight/Fog/Constraints + `in_flight_ticket`
  frontmatter. Prior-Decisions/Next-Steps RELOCATE to recall/ticket pointers, never delete.
- Full rationale + 20-row change map: `.memory/specs/ticket-plan-handoff-workstream.md`.

## Current State
This session was pure DESIGN + ticketing — no implementation code written for 148/149/150.
Reference `tkt ready` for frontier. In-head-not-in-a-file: nothing pending — all analysis is in
the tracked spec, all tickets self-sufficient (refs point to tracked paths, verified).

## Next Steps
1. Implement in order: 150 (has an eval to catch regression) → 148 → tkt#173 + 149 (cross-repo, ADR).
2. 150 MUST update `handoff-decaying-resolution.yaml` criteria in the same change + re-run 5 trials
   (eval is flaky at the delta gate; relocate-don't-delete or it false-fails).
3. 148 ships with a new `activation-plan-ticket-sync.yaml` (zero coverage today).
4. 149 authors an ADR reversing ticket 64 (sync-plan --fix) + files the tkt companion ticket.

## Fog
Whether 149 should retire `sync-plan` entirely or narrow it to Title-only drift — depends on
whether the tkt CLI keeps any plan awareness after the slim. Decide during 149 with the tkt owner.

## Evidence
- `.memory/specs/ticket-plan-handoff-workstream.md` (3-layer model, all 3 parts, change map, exec order)
- Tickets: `.tickets/148,149,150-*.md`; tkt repo `.tickets/173-*.md`
- Design basis: `design/patterns/automate-or-drop.md`, `design/forces/{ceremony-decays,pf-plan-reflects-truth}.md`
- Commits: 85537bd (spec+ticket refs), f26dc81 (guidance-sync gate), tkt 4233d1e (durable-refs rule)

## Recommended Updates
- [ ] (150) handoff restructure will itself apply the leaner shape this handoff still uses — expected
- [ ] CONTEXT.md: 11 verbose entries could trim + 4 gate-failures to route (subagent-reviewed, deferred — needs a decision)
