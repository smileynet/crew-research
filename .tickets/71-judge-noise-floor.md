---
id: "71"
title: "Declare a delta noise floor for single-family judge panels"
status: done
blocked_by: []
env: either
spec: "eval-harness"
---

# Declare a delta noise floor for single-family judge panels

## What to build

Same-family affinity is roughly a 3–9% thumb on the scale (Preference Leakage, ICLR 2026:
same family same series 8.9%, different series 2.8%). Our definition delta thresholds are
0.5–1.0 points on a 5-point scale, and 18 definitions use `delta_threshold: 0`. A
single-family panel can therefore flip a near-threshold verdict on affinity alone — and
until ticket 70 lands, every corp run is single-family.

Declare and enforce a noise floor: when a row's `panel.families < 2`, a delta below
~0.3 points is not evidence of skill effect. Mechanism options (pick one, cheapest first):

- Report-only: `check-staleness.sh` or the summary flags rows where
  `panel.families < 2 AND |delta| < floor` as INCONCLUSIVE rather than PASS/FAIL
- Status-level: introduce an `INCONCLUSIVE` status for those rows (bigger change —
  every consumer of scores.jsonl statuses has to learn it)

Prefer report-only unless a consumer actually needs the status. Do NOT retroactively
rewrite historical rows; the `panel` field is absent before 2026-07-29 and its absence
means "unknown", not "fine".

## Acceptance criteria

- [x] Floor value chosen with the reasoning recorded (why 0.3 and not 0.1 or 0.5)
- [x] Single-family rows with sub-floor deltas are visibly marked in the run summary
- [x] The rule is documented where eval results are interpreted (eval-harness skill), not
      only in code
- [x] Historical rows without a `panel` field are treated as unknown, not as passing
- [x] Test covering: single-family sub-floor (flagged), single-family above-floor (not
      flagged), multi-family sub-floor (not flagged)

## Resolution (2026-07-31)

Floor=0.5 (research: MDE at 3 trials + same-family bias). Report-only annotation (INCONCLUSIVE) + noise_floor_hit JSON field. 8/8 tests pass. Status unchanged — consumers unaffected.
