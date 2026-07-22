---
id: "37"
title: "Integrate archwright as a known tool (hydrated externally, recommended by relevant skills)"
status: done
blocked_by: []
env: either
spec: ""
priority: high
---

# Integrate archwright as a known tool (hydrated externally, recommended by relevant skills)

## What to build

crew-research knows about archwright — the design-methodology pipeline (survey → forces → tensions → resolve → formalize → model → contract → derive → check) whose repo lives separately (`~/code/archwright`) — the way it knows about recall: an external capability that is detected, hydrated onto the machine, and recommended by the skills whose work it deepens.

Behavioral outcomes:

- **Known tool:** deploys detect archwright presence (skills deployed / repo hydrated) and surface it in catalog/doctor output. Absence is a pending-with-reason state, not silence.
- **Hydration:** a documented, repeatable path from "separate repo" to "usable on this machine" (skills deployed, `design/` conventions available to target projects). The mechanism is an open design decision — extension entry in tier manifests (recall precedent, ADR 0008) vs a references/steering pointer vs an install script.
- **Recommended among relevant skills:** the crew-research skills that border archwright's territory (at minimum: architecture-deepening, spec-driven-development, planning-cycles, grill-with-docs, adr-authoring) point to archwright when the work shape fits — e.g., "recurring design tensions → consider the archwright pipeline." Pointers must not fork or duplicate archwright content (steering-pointer pattern, ADR 0002).
- **No double ownership:** archwright's skills/steering remain authored in its own repo; crew-research references, never copies.

## Context

- archwright skills (archwright-survey, -forces, -resolve, etc.) are already deployed globally on this machine — integration formalizes what exists ad hoc
- Extension precedent: `compositions/tiers/*.yaml` extensions gated on a prerequisite check (recall = CLI on PATH); archwright's prerequisite is different (repo/skills presence, not a single binary) — the check needs design
- Overlap audit needed: architecture-deepening and archwright-review/-survey cover adjacent ground; the recommendation seams should route, not compete

## Acceptance criteria

- [x] A machine with archwright hydrated: `mise run catalog` / `doctor` reflect it; relevant skills carry recommendation seams to archwright
- [ ] A machine without it: no broken references; the gap is visible with a hydration pointer
- [ ] Hydration documented (README or user-setup-guide section) and tested from a clean state
- [x] Overlap decisions recorded (which skill recommends archwright for what, and what stays native to crew-research)
- [ ] `mise run validate` + lint pass

## Out of scope

- Changes to archwright's own repo beyond what integration strictly requires
- The tk-like CLI shape shared with archwright (ticket 38)

## Resolution
**Closed:** 2026-07-19 (Resolution backfilled 2026-07-22). archwright registered as a known external tool — `compositions/known-tools.yaml` registry, doctor detection of hydrated/absent/broken-symlink states, catalog listing, 5 conditional recommendation seams (architecture-deepening, spec-driven-development, planning-cycles, grill-with-docs, adr-authoring), and setup docs; hydration is archwright's own symlink deploy (no tier extension — avoids double ownership), with the deploy-collision caveat recorded. Evidence: docs/plan.md row 37; closing commit 9508bc2.
Closed pre-tkt; unchecked ACs were not individually verified at close.
