---
id: "74"
title: "Audit reports for agreement-as-confidence; require ICC + chance-corrected stats"
status: done
blocked_by: []
env: either
spec: "eval-harness"
---

# Audit reports for agreement-as-confidence; require ICC + chance-corrected stats

## What to build

Two measurement rules from the 2026 judge literature that our reporting does not yet
respect:

1. **Judge agreement is not a confidence signal.** Unanimous 9-judge panels were 90.9%
   accurate where independence predicts ~99.99%; 51 items had all nine judges wrong.
   Anywhere a report treats judges agreeing as evidence the score is right, remove it.
2. **Raw agreement overstates chance-corrected agreement by 34–41 points** (85% raw ≈
   κ 0.48). Any future judge-comparison work must report a chance-corrected statistic,
   and correlation work must use ICC rather than Pearson — Pearson ignores calibration
   shifts, which are exactly what differ between judge families.

Audit scope: `tools/evals/scripts/`, the eval-harness skill, `docs/development/eval-*`
result write-ups, and any summary the harness prints. This is a read-then-fix pass, so
expect the diff to be small or empty in places — record where it was already correct.

Also worth measuring while here: our own inter-judge correlation (γ̄) is computable from
any retained results dir that has per-judge scores in `task_scores[].judges`. The
published effective-independence ceiling (~2–2.6 judges) was measured on classification
and pairwise preference, never on open-ended generation — so our number is unknown and
cheap to get. Do NOT cargo-cult the panel floor of 3 without it.

## Acceptance criteria

- [ ] Every place agreement is used as confidence is identified, with a fix or an explicit
      "already correct" note
- [ ] A documented rule: chance-corrected stats for agreement, ICC (not Pearson) for
      correlation — placed where someone writing the next results doc will see it
- [ ] Our own γ̄ measured from a retained results dir, with n stated, or a recorded reason
      it cannot be computed (e.g. all retained rows are single-judge — which is likely, and
      is itself the finding)
- [ ] If γ̄ is measurable and contradicts the floor of 3, ADR 0010's amendment gets a
      follow-up note rather than a silent change

## Resolution (2026-07-31)

Audit: all claims already correct (ADR 0010 addressed this). Stats rule added to eval-harness skill. gamma-bar unmeasurable (per-judge scores not retained) -- documented as measurement gap; floor of 3 justified independently on bias grounds.
