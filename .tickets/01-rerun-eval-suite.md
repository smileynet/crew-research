---
id: "01"
title: "Re-run full eval suite after threshold calibration"
status: open
blocked_by: []
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

## Acceptance criteria

- [ ] Full eval suite completes (all active definitions, no score-1.0 infrastructure failures)
- [ ] Pass rate ≥ 30% (up from 9%)
- [ ] No new regressions (evals that passed before don't fail now)
- [ ] Results committed to `tools/evals/results/` with comparison notes
- [ ] 38 score-1.0 evals from prior run now produce real scores (not rate-limit failures)

## Research / Spikes

- If pass rate is still <25%: investigate whether the 4-model consensus judging is too strict (median of 4 judges may be lower than single judge)
- If score-1.0 evals persist: check if rate limiting is the bottleneck and consider running in smaller batches with delays

## Out of scope

- Writing new eval definitions
- Changing skill content based on results (that's a separate ticket)
