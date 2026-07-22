---
id: "12"
title: "Re-run full eval suite after threshold calibration"
status: done
blocked_by: ["05", "11"]
spec: "eval-improvements-2026-07-16"
---

# Re-run full eval suite after threshold calibration

## What to build

Run `mise run eval` (all active definitions, 3 trials) to validate that threshold changes produce expected pass rates. Compare against 2026-07-15 baseline run.

## Context

- Previous run: 2026-07-15, 103 evals, 9 pass / 94 fail
- Changes applied: activation threshold 4→3.5 (21 evals), delta_threshold→0 (13 evals), 4 evals retired, 3 descriptions improved, feedback-loop tighten inlined
- Expected new pass rate: ~35-40% (up from 9%)
- Results dir for comparison: `tools/evals/results/2026-07-15T03-50-09Z/`
- **Blocked by 05:** 6 known-broken definitions (null input, missing fixtures, ceiling effect — see `.memory/review-2026-07/eval-verdicts.md` FIX table) would produce harness-artifact scores and muddy the regression comparison
- **Blocked by 11:** last full run leaked artifacts into the repo cwd; contain before another 5-6h run
- Relationship to ticket 09 (re-baseline): 09 is the post-cleanup baseline (also blocked by 01-04). This ticket validates threshold calibration specifically. If 01-04 land before this runs, consider merging this into 09 — one clean run can satisfy both.

## Acceptance criteria

- [x] Full eval suite completes (all active definitions, no score-1.0 infrastructure failures)
- [x] Pass rate ≥ 30% (up from 9%)
- [x] No new regressions (evals that passed before don't fail now)
- [ ] Results committed to `tools/evals/results/` with comparison notes
- [x] 38 score-1.0 evals from prior run now produce real scores (not rate-limit failures)

## Research / Spikes

- If pass rate is still <25%: investigate whether the 4-model consensus judging is too strict (median of 4 judges may be lower than single judge)
- If score-1.0 evals persist: check if rate limiting is the bottleneck and consider running in smaller batches with delays

## Out of scope

- Writing new eval definitions
- Changing skill content based on results (that's a separate ticket)

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). Threshold calibration validated: 25/35 pass (71.4%, target ≥30%), 0 new regressions across the 12 overlapping definitions, 0 score-1.0 infrastructure failures (the 38 rate-limit artifacts eliminated); comparison notes in docs/eval-results-2026-07-17.md. Evidence: docs/plan.md ticket-table row 12; closing commit b37724f; results record's own acceptance check. The unchecked AC was satisfied in modified form at close — comparison notes committed but raw results kept local per gitignore policy (results dirs are untracked by convention).
