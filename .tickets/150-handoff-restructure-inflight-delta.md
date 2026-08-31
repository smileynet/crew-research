---
id: "150"
title: "Restructure handoff to in-flight delta shape + in_flight_ticket frontmatter"
status: open
blocked_by: []
---

# Restructure handoff to in-flight delta shape + in_flight_ticket frontmatter

## Context

In a ticket-based workflow with recall + a slimmed (narrative-only) PLAN.md, the current
handoff is over-specified: it DUPLICATES ticket status (violating its own "never duplicate
ticket status" rule) and DOUBLE-BOOKS decisions with recall/ADR. Evidence it's redundant:
`read-handoff` already re-derives progress from `git log base..HEAD` (step 3), plan narrative
(step 5), and `.tickets/` frontier (step 6) — it never needed the handoff to restate the roster.

Governing model (three memory layers, distinct jobs): tracker owns status/deps/ACs; persistent
store (recall/ADR/specs) owns durable decisions + why; **handoff owns ONLY volatile in-flight
state + next action** (one-session lifespan). The handoff is the volatile delta on top of
durable layers, never a mirror of them ("stateless agent, stateful system").

## What to build

Restructure `atomics/skills/handoff/SKILL.md` required sections:
- **KEEP:** Objective (tighten — drop per-ticket status recap), Constraints (strongest-earning:
  session-live env facts blocking the next step), Fog (unique — un-ticketable interpretive
  questions), Recommended Updates (propagation inbox), Evidence (as terse POINTERS — drop the
  commit list, derivable from base_commit..HEAD).
- **COLLAPSE:** Prior Decisions → point to recall/ADR (durable decisions live there); keep only
  session-scoped rationale. Current State → in-flight delta ONLY (uncommitted/mid-edit work,
  in-head findings, why-this-approach, dead-ends); drop the ticket roster + "working tree clean".
  Next Steps → the in_progress ticket body + `tkt ready` own this.
- **NEW frontmatter field `in_flight_ticket:`** replaces the roster (ephemeral .scratch/ file,
  operator-owned — not a .tickets/ contract field, so ceremony-decays doesn't bind it).
- Proposed shape: Focus / In-Flight / Fog / Constraints (+ optional Pointers, Recommended Updates).
- **read-handoff:** verify-only — steps 3/5/6 already work without the roster; confirm, no functional change.

## CRITICAL: relocate, never delete + update the covering eval

- **handoff HAS an active eval** — `handoff-decaying-resolution.yaml` (10-pt rubric: AUTOMATIC
  FAIL if >80 lines, rewards compression/decay/next-steps/evidence/handoff_key). **Update its
  criteria in the SAME change** (id immutable, criteria mutable) or it false-fails/false-passes.
  The eval is FLAKY at the delta gate — re-run 5 trials before concluding regression.
- **Lesson from agents-md-authoring:** a "trim" eval FAILED because trimming DELETED content
  instead of relocating it ("a link to a file that doesn't exist is deletion, not extraction").
  Prior Decisions/Next Steps must RELOCATE to recall/ticket pointers, never vanish.
- Risk: MEDIUM (eval exists to catch regression). Handoff is a floor-raiser — don't drop a
  proven floor behavior; leaner must mean compress/relocate.

## References

- `.scratch/subagent-raw/handoff-necessity.md` (per-section verdict + leaner shape)
- `.scratch/subagent-raw/eval-regression-risk.md` (eval coverage, flakiness, relocate-not-delete)
- `.scratch/research/handoff-priorart.md` (three-layer model, point-don't-paste)
- Relates: 148 (readiness nudge line), 149 (removes the handoff sync-plan step)

## Acceptance criteria

- [ ] handoff SKILL.md restructured to Focus/In-Flight/Fog/Constraints (+ optional Pointers/Recommended Updates); `in_flight_ticket` frontmatter added
- [ ] Prior Decisions + Next Steps RELOCATED to recall/ADR/ticket pointers (not deleted)
- [ ] `handoff-decaying-resolution.yaml` criteria updated to match the new shape; re-run 5 trials, no regression (flake ruled out)
- [ ] read-handoff verified to work without the roster (no functional change needed)
- [ ] `mise run validate` + lint pass
