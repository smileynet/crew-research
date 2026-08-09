---
id: "94"
title: "Spike: geometric median aggregation for eval judging"
status: done
blocked_by: []
env: either
spec: "eval-harness"
priority: normal
---

# Spike: Geometric Median Aggregation for Eval Judging

## Hypothesis

Replacing current consensus aggregation with geometric median (per RoPoLL, AWS 2026) will
make judging more robust to individual judge failures — a single hallucinating judge cannot
drag the aggregate arbitrarily far from truth. RoPoLL: 3-judge geometric median at 38B
beats a single 675B judge by 1.31× under 30% corruption.

## Baseline to measure against

1. **Current state**: Read harness code to confirm aggregation method (likely majority vote
   or arithmetic mean).
2. **Baseline measurement**: From last full eval run's `scores.jsonl`, record individual
   judge scores and current aggregate. Identify outlier cases (single judge >2σ from mean).
3. **Corruption rate**: How often does a judge produce parser failure or obviously wrong score?

## Spike design

1. Document current aggregation logic (code reference in `tools/evals/harness/`).
2. Implement geometric median as alternative (for 1D scores: spatial median = standard median).
3. Re-score the last eval run. Compare: how many definitions change verdict?
4. Robustness test: corrupt one judge's scores artificially. Measure aggregate movement
   under current method vs geometric median.

## Validation criteria

- [ ] Current aggregation method documented with code reference
- [ ] Geometric median re-scoring produces results on the last full run
- [ ] ≤5% of definitions change verdict (if more, current method has a problem)
- [ ] Under simulated corruption, geometric median moves ≤50% as far as current method
- [ ] Implementation is a drop-in replacement (same inputs/outputs)

## Reject if

- Current method is already median-based (adds nothing)
- Judge scores are binary pass/fail (geometric median needs continuous scores)
- Corruption rate in practice <5% (robustness gain doesn't justify complexity)
- Changing aggregation invalidates historical comparisons without re-scoring

## References

- Research: `.scratch/research/judge-as-gate.md` (RoPoLL section)
- Eval harness: `tools/evals/harness/run.sh`
- RoPoLL paper: arXiv 2606.30931

## Resolution (2026-08-09)

ALREADY IMPLEMENTED. Eval harness already uses median aggregation (run.sh L558-567). Even-panel rule: lower middle score wins (documented, ADR 0010 amendment). RoPoLL referenced in code comments. Panel degradation flagging for n<3, single-family, etc. already in panel_json(). No work needed.
