---
id: "26"
title: "Eval baseline record reflects the post-baseline fix batch"
status: open
blocked_by: []
spec: "t09-baseline-followups"
---

# Eval baseline record reflects the post-baseline fix batch

## What to build

One fresh full suite run and an updated baseline record. The 2026-07-17 baseline (26/35 judged, 8 known gaps; 19/20 activation) is stale after tickets 13/14/19: three former failures now pass or are retired, and the regression rule ("any NEW failure outside the 8 known gaps") needs a new reference set.

## Context

- **Changes since baseline @ 24d9691:** architecture-deepening-rubber-stamp now passes (ticket 13); feedback-loop-effectiveness + feedback-loop-tighten-effectiveness now pass via bug-injected fixtures — pre-2026-07-18 history flagged non-comparable in the def (ticket 14); activation-recall retired (ticket 19); new def activation-architecture-deepening (passing)
- **Expected outcome:** judged ≥29/35 with ~5 remaining known gaps (was 8; verify each is still a genuine gap); activation 20/20 live defs
- **Use the new resume flag** if the run interrupts: `run.sh --all --skip-completed <dir>` (ticket 15)
- **Run discipline:** `setsid nohup`, no script edits mid-run, ~8-10h for the judged suite (eval-execution steering)
- **Files:** `docs/development/eval-baseline-2026-07-17.md` (record to supersede or amend), `tools/evals/definitions/` (known_gap frontmatter accounting)

## Acceptance criteria

- [ ] Full judged suite + activation suite run at a recorded commit
- [ ] Baseline record updated (or a dated successor written): pass counts, per-def deltas vs old baseline, revised known-gap list with each gap re-justified
- [ ] Regression rule restated against the new reference set
- [ ] Any NEW unexplained failure triaged into a ticket before the record is finalized

## Out of scope

- Fixing failures found (separate tickets, like this batch)
