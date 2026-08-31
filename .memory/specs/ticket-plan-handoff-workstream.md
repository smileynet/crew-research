---
type: spec
title: "Ticket-Readiness + PLAN.md-Slim + Handoff-Restructure Workstream"
status: proposed
created: 2026-08-31
tickets: [148, 149, 150]
cross_repo_tickets: ["tkt#173"]
---

# Ticket-Readiness + PLAN.md-Slim + Handoff-Restructure Workstream

Durable research + design basis for tickets 148/149/150 (crew-research) and tkt#173.
Consolidated from four dispatched research rounds (2026-08-31). This is the tracked
source of truth — the tickets cite THIS file, not the ephemeral `.scratch/` originals.

**Unifying theme:** as tickets became self-sufficient and the frontier became computable
(`tkt ready`), the older artifacts that *duplicated* ticket state (PLAN.md status tables,
the handoff roster) became drift-generating ceremony. The fix is one principle across all
three: **each layer owns one thing; point, don't paste.**

Three-memory-layer model (prior art: agent session-continuity + SSoT literature):
- **Task tracker (`.tickets/`)** owns: what work exists, status, ordering, deps, ACs.
- **Persistent store (recall / ADR / `.memory/specs`)** owns: durable decisions + why, constraints.
- **Handoff note (`.scratch/HANDOFF.md`)** owns ONLY: volatile in-flight state + next action.
Anything duplicated across these is the drift surface to remove.

---

## Part 1 — Ticket readiness (Definition of Ready)  → tickets 148 (judgment) + tkt#173 (mechanical)

**Gap:** `tkt validate` checks structural correctness; `audit`/`close` check the CLOSE event.
NOTHING checks an OPEN, frontier-eligible ticket has enough to START. The content bar lives
only in Level-4 prose (ticket-standards.md) with no mechanical backstop, never re-checked.

**Two-bar definition:**
- WELL-FORMED (any status): valid frontmatter, a What-to-build section, ≥1 AC checkbox.
- READY-TO-START (open + deps done): adds an intent source (spec/ADR/blocked_by/user-request/
  discovery), a Context section with ≥1 file path/link, references to prior work, concrete
  testable (not procedural) ACs.

**Layered enforcement (enforcement-hierarchy: mechanical floor + judgment layer):**
- MECHANICAL (Level 2, grep-able) → tkt#173: intent-source present, Context+≥1 link present,
  ≥1 AC checkbox, blocked_by resolves. Frontier-scoped. Warn-by-default, error under `--strict`.
  Re-checks the standing backlog (creation-only checks rot). Advisory, never hard-block.
- JUDGMENT (Level 3) → ticket 148: is the context SUFFICIENT to do the work; do references
  point to CURRENT work; are ACs testable not procedural. Lives in plan-ticket-sync +
  project-cleanup Phase 5 + a handoff nudge.

**Prior art (verified):** Definition of Ready (entry gate, mirror of DoD) + INVEST. Mechanical
DoR gating is real: Jira **Field Required Validator** (blocks a transition until required fields
present — the near-exact analog), Linear **LineGuard/Required** (webhook revert + explain).
GitHub Issue Forms enforce required fields but can't validate links point to real artifacts.
GitLab: no native issue-field gate. → the `tkt validate` rule is precedented, not novel.

**Eval obligation:** plan-ticket-sync has ZERO eval coverage (no active/retired def) — ship
148 with `activation-plan-ticket-sync.yaml` (5 pos / 5 neg).

---

## Part 2 — PLAN.md is two layers; slim to narrative  → ticket 149 (+ tkt cross-repo)

**Verdict: REPLACE-WITH-LIGHTER, not deprecate.** The "PLAN.md is obsolete" claim is half-right.

- **TABULAR layer** (per-ticket status, blocked_by, frontier) — FULLY REDUNDANT with `.tickets/`,
  the single source of drift. `tkt ready` computes the frontier live and never goes stale.
- **NARRATIVE layer** (campaign arc + dated goals, "why this order" ordering rationale, the
  14-area codebase inventory, per-campaign outcome+evidence ledger, onboarding roadmap) — NOT
  expressible in a flat ticket set. Tickets have no home for campaign prose or ordering reasons.

**Cost of the redundant layer (all exist ONLY to fight tabular drift):** the plan-ticket-sync
row-maintenance duty, `tkt sync-plan` + the researched `sync-plan --fix` (ticket 64), a
per-session handoff sync step, and the force `pf-plan-reflects-truth`. Remove the derivable
columns → the whole drift class retires; prose isn't derivable so nothing re-drifts.

**Prior art (verified):** tektoncd/pipeline `roadmap.md` (L1) = narrative-only doc + label-fed
board with the rule "don't manually set Done — let automation handle it" — the exact target.
Hand-maintained status table is the recognized anti-pattern; consolidate to one source, generate
the rest.

**Design ALREADY RESOLVED — no archwright pipeline needed** (cite these tracked artifacts):
- `design/patterns/automate-or-drop.md` (★★ active): "Every contract field has a named owner,
  or it isn't in the contract" — owner is the TOOL, the OPERATOR (with validate as feedback), or
  nothing (dropped). "Ceremony with no owner is not added."
- `design/forces/ceremony-decays.md` (hard constraint): "Metadata not maintained by tooling
  decays … a field is either automated or dropped from the contract."
- `design/forces/pf-plan-reflects-truth.md`: "operator directive (ticket 024) polices against a
  third status copy." The slim IS the application of automate-or-drop to this invariant.

**spec-driven-development SURVIVES UNTOUCHED** — it uses PLAN.md as a NARRATIVE map
(Destination/Phases/Decisions/Task Graph/Fog/Out-of-scope per spec-template.md), never a status
table. `read-handoff` already re-derives progress from `git log base..HEAD` (step 3) + narrative
plan (step 5) + `.tickets/` frontier (step 6), explicitly "write as narrative, not a status
table" — verify-only, no functional change.

**Cross-repo flag:** `sync-plan` is a **tkt CLI subcommand in D:/code/tkt** (+ its
`design/specs/cli-outputs.yaml` sync-plan-findings). Retiring the tabular machinery has two
halves — crew skill/steering refs (ticket 149) AND the tkt command (a tkt-repo companion ticket).
De-scoping `sync-plan --fix` reverses ticket 64's research → **ADR-worthy**.

---

## Part 3 — Handoff is over-specified; restructure to the in-flight delta  → ticket 150

**Verdict: RESTRUCTURE.** The current handoff DUPLICATES ticket status (violating its own
"never duplicate ticket status" rule) and DOUBLE-BOOKS decisions with recall/ADR.

**Per-section:** KEEP Constraints (session-live env facts, strongest-earning), Fog (unique —
un-ticketable interpretive questions), Recommended Updates, Evidence (as terse pointers — drop
the commit list, derivable from `base_commit..HEAD`), Objective (tightened). COLLAPSE Prior
Decisions → point to recall/ADR; Current State → in-flight delta ONLY (drop the ticket roster +
"working tree clean"); Next Steps → the in_progress ticket body + `tkt ready` own it.

**Proposed shape:** Focus / In-Flight / Fog / Constraints (+ optional Pointers, Recommended
Updates) + a new `in_flight_ticket:` frontmatter field replacing the roster (ephemeral,
operator-owned, not a contract field). Handoff = the volatile delta on durable layers, never a
mirror ("stateless agent, stateful system").

**Eval obligation + regression guard:**
- handoff HAS an active eval — `handoff-decaying-resolution.yaml` (10-pt rubric, AUTOMATIC FAIL
  if >80 lines, rewards compression/decay/next-steps/evidence/handoff_key). **Update its criteria
  in the same change** (id immutable, criteria mutable) or it false-fails/false-passes. It is
  FLAKY at the delta gate — re-run 5 trials before concluding regression.
- **Lesson (agents-md-authoring):** a "trim" eval FAILED because trimming DELETED content instead
  of relocating it ("a link to a file that doesn't exist is deletion, not extraction"). Prior
  Decisions/Next Steps must RELOCATE to recall/ticket pointers, never vanish. Risk: MEDIUM.

---

## Change map (20 refs: 8 load-bearing / 9 incidental / 3 coordinate-or-annotate)

| File | Type | Change | Ticket |
|------|------|--------|--------|
| `atomics/skills/handoff/SKILL.md` §Required Sections | load-bearing | recast to Focus/In-Flight/Fog/Constraints | 150 |
| `atomics/skills/handoff/SKILL.md` frontmatter template | load-bearing | add `in_flight_ticket:` | 150 |
| `atomics/skills/handoff/SKILL.md` Promotion step 5 | load-bearing | retire `tkt sync-plan --check` step | 149 |
| `atomics/skills/plan-ticket-sync/SKILL.md` (row-maintenance steps) | load-bearing | drop per-ticket-row duty; keep currency/ordering audit → readiness (148) | 149+148 |
| `atomics/skills/project-cleanup/SKILL.md` Phase 5 + `references/phase-checklist.md` | load-bearing | drop sync-plan calls; add readiness line | 149+148 |
| `AGENTS.md` sync-plan command docs | load-bearing | update/remove when tabular machinery retires | 149 |
| `docs/plan.md` | load-bearing | THE file to slim: drop status/blocked_by/frontier tables → `tkt ready`/`tkt board` pointer; keep narrative | 149 |
| `tools/evals/definitions/effectiveness-project-cleanup.yaml` + `fixtures/project-cleanup-workspace.yaml` | load-bearing | update the sync-plan criterion + fixture plan.md format | 149 |
| `design/specs/cli-outputs.yaml` sync-plan-findings (tkt repo) | coordinate | tkt-repo half of sync-plan retirement | tkt companion |
| `.memory/specs/ticket-cli-spec.md` R9/R9a | annotate | mark sync-plan --fix decision superseded when 149 lands | 149 |
| spec-driven-development, read-handoff, plan-prereqs, cheatsheet, grill-with-docs refs | incidental | narrative-map mentions — NO edit (verify only) | — |

Design-gate result: 149 → direct edits (design pre-resolved); 150 → direct edits (below
threshold, one trivial field-ownership answer). Neither needs an archwright pipeline.

---

## Recommended execution order

150 (D — has an eval to catch regression) → 148 (A) → tkt#173 (B) + 149 (C, cross-repo + ADR).
