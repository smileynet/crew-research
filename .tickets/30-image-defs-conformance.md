---
id: "30"
title: "image-* eval defs conform to suite conventions (ids, adapter scoping, deferred birth run)"
status: open
blocked_by: ["29"]
spec: "t09-baseline-followups"
---

# image-* eval defs conform to suite conventions (ids, adapter scoping, deferred birth run)

## What to build

Bring the three image-handling defs from upstream 5a23e45 (`image-greedy-tool-detection`, `image-multi-validator-consensus`, `image-no-vision-honesty`) up to suite conventions, and register their birth runs as owed in the deferred-run ledger (this machine has no crush/agy access).

## Context

- **Missing immutable `id:` fields** (verified: `grep -c "^id:"` → 0 for all three) — convention landed 2026-07-18 on all 111 defs; baseline invariant requires ids for longitudinal comparison
- **Designed for crush** ("no native vision — steepest behavioral delta") but currently selected by kiro-cli `--all` runs — needs `adapters:` scoping from ticket 29
- **No recorded runs anywhere** — untested at birth; the conformance-at-birth rule wants a run including at least one scenario that can genuinely fail
- **Baseline invariants stale:** judged suite is now 39 defs (was stated 36 in the 2026-07-19 record amendment)
- **Files:** `tools/evals/definitions/image-*.yaml`, `docs/development/eval-baseline-2026-07-19.md`, `docs/development/deferred-runs.md` (from ticket 29)

## Acceptance criteria

- [ ] All three defs carry immutable `id:` + `adapters:` scoping; lint clean (incl. fixing the existing warning: `image-handling: references/tool-dispatch.md not linked from SKILL.md body`)
- [ ] kiro-cli `--all` run shows them as SKIP-with-reason, not run and not counted
- [ ] Deferred-run ledger entries created (owed: crush birth run per def)
- [ ] Baseline record corrected: judged counts restated (≥29/39 with 3 pending-by-adapter), regression rule unambiguous about SKIPped defs
- [ ] When a crush-capable machine runs them: results summarized into the baseline record and ledger rows closed (this criterion may complete on another machine — leave checked-off state to that run)

## Out of scope

- Def content/criteria changes beyond frontmatter conformance
- Vision capability work on this machine
