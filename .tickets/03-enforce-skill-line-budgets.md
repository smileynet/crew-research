---
id: "03"
title: "Over-budget skills fit the 100-line limit via progressive loading"
status: done
blocked_by: ["02"]
spec: "project-review-followup"
---

# Over-budget skills fit the 100-line limit

## What to build

Every tier skill is under 100 lines (or carries a documented justification), with overflow content moved to `references/` files that are linked from the body. Skill quality is preserved — check any skill with a passing eval still passes after trimming.

## Context

- **Relevant files:** `.memory/review-2026-07/skill-verdicts.md` (P2 section)
- **Blocked by 02** because dedup changes line counts — trim after content settles
- **Offenders:** grill-with-docs (166), multi-agent-validation (142), planning-cycles (125), script-authoring (121), project-cleanup (116), spec-driven-development (116), vertical-slice-planning (111)

## Acceptance criteria

- [ ] All 7 listed skills ≤100 lines OR have a justification comment in frontmatter
- [ ] Moved content lives in references/ and is linked from the body (lint: 0 orphan warnings for these skills)
- [ ] Skills with existing effectiveness evals re-run and still pass (grill, spec-driven-development at minimum)
- [ ] Redeployed and `mise run doctor` healthy

## Out of scope

- Steering files (ticket 04 — different budget model, always-on cost)
