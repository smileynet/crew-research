---
id: "149"
title: "Slim PLAN.md to narrative-only, retire sync-plan tabular drift machinery (cross-repo, ADR)"
status: open
blocked_by: []
---

# Slim PLAN.md to narrative-only, retire sync-plan tabular drift machinery (cross-repo, ADR)

## Context

`docs/plan.md` is two layers: a TABULAR layer (per-ticket status/blocked_by/frontier) that
is **fully redundant with `.tickets/` and the sole source of drift**, and a NARRATIVE layer
(campaign arc, "why this order" ordering rationale, codebase inventory, onboarding roadmap)
that tickets structurally cannot hold. An entire skill's duty (plan-ticket-sync row
maintenance), a CLI feature (`tkt sync-plan --fix`, ticket 64), a per-session handoff sync
step, and the force `pf-plan-reflects-truth` ALL exist only to fight the tabular layer's drift.

**Verdict from analysis: replace-with-lighter, NOT deprecate.** The literal "delete PLAN.md"
reading would gut spec-driven-development and delete non-recoverable ordering/decision
rationale for zero gain.

Design is ALREADY RESOLVED (no archwright pipeline needed) — cite existing artifacts:
- `design/patterns/automate-or-drop.md` (★★): "Every contract field has a named owner, or it isn't in the contract"
- `design/forces/pf-plan-reflects-truth.md`: polices against a third status copy
- `design/forces/ceremony-decays.md`
Prior art: tektoncd/pipeline roadmap.md (narrative + label-fed board, "don't manually set Done —
let automation handle it") — the exact target shape. Hand-maintained status table = recognized anti-pattern.

## What to build

1. **Slim `docs/plan.md`** — keep narrative only (campaign arc, ordering rationale, inventory,
   fog); DROP the status/blocked_by/frontier tables; replace with a pointer to `tkt ready` / `tkt board`.
2. **Trim `plan-ticket-sync`** — remove the per-row status-maintenance step (its new job is
   readiness judgment, ticket 148). RELOCATE, don't delete.
3. **CROSS-REPO (tkt, D:/code/tkt):** retire/narrow `tkt sync-plan --fix` and the tabular
   drift-detection; update `design/specs/cli-outputs.yaml` sync-plan-findings. **File a companion
   tkt ticket** — this half does NOT live in crew-research.
4. **ADR reversing ticket 64** — ticket 64 researched+endorsed `sync-plan --fix`; retiring it
   reverses that. `.memory/adr/NNNN-retire-sync-plan-tabular.md`.
5. **Retarget incidental refs** — handoff L70 sync-plan promotion step, project-cleanup L67/80 +
   phase-checklist L47-48, AGENTS.md L49-50. (spec-driven-development SURVIVES UNTOUCHED — uses
   PLAN.md as a narrative map, not a status table. read-handoff already re-derives progress from
   git+tickets — verify-only.)
6. **Update the covering eval** — `effectiveness-project-cleanup.yaml` L33 + fixture
   `project-cleanup-workspace.yaml` L154 reference plan.md sync; update in the same change.

## References

- **`.memory/specs/ticket-plan-handoff-workstream.md` § Part 2 + Change map** — the two-layer analysis
  (tabular=redundant / narrative=irreducible), maintenance-cost breakdown, tektoncd prior art, the full
  20-row change map, and the cross-repo flag (TRACKED source of truth)
- Design basis (TRACKED): `design/patterns/automate-or-drop.md` (★★), `design/forces/ceremony-decays.md`,
  `design/forces/pf-plan-reflects-truth.md`
- Relates: 148 (frees plan-ticket-sync), 150 (handoff sync-step removal overlaps), tkt companion (sync-plan CLI)

## Acceptance criteria

- [ ] docs/plan.md is narrative-only; status tables replaced with a `tkt ready` pointer
- [ ] plan-ticket-sync row-maintenance step removed (relocated to readiness per 148)
- [ ] companion tkt ticket filed for `sync-plan --fix` retirement (cross-repo half)
- [ ] ADR authored reversing ticket 64
- [ ] incidental refs retargeted; spec-driven-development untouched (verified); effectiveness-project-cleanup eval + fixture updated
- [ ] `mise run validate` + lint pass; no dangling plan.md status-table references
