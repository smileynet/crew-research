---
id: "97"
title: "Spike: learned feedback filtering for review findings (Greptile pattern)"
status: open
blocked_by: ["92"]
env: either
spec: "eval-harness"
priority: normal
---

# Spike: Learned Feedback Filtering for Review Findings

## Hypothesis

Storing embeddings of previously-dismissed review findings in recall and filtering future
findings by similarity to past-dismissed patterns will achieve Greptile's result: moving
from ~19% acceptance to 55%+ by learning team-specific preferences rather than relying on
universal severity classification. Depends on ticket 92 establishing the baseline.

## Baseline to measure against

1. **Ticket 92's output**: Baseline precision/recall/noise rates for dispatch-codex-review.
2. **Feedback history**: After running reviews for N sessions, accumulate a corpus of
   "addressed" vs "dismissed" findings. Minimum viable: 30 addressed, 30 dismissed.
3. **No learned filter**: Compare against the judge-gate approach (ticket 92) alone.

## Spike design

1. **Capture feedback loop**:
   - When a review finding leads to a code change → mark as "addressed"
   - When a finding is ignored or explicitly dismissed → mark as "dismissed"
   - Store both with their embeddings in recall (`--type review-feedback`)

2. **Build filter**:
   - On new finding: embed it, compute cosine similarity to top-K dismissed findings
   - If similarity to ≥3 dismissed findings exceeds threshold → suppress
   - This is Greptile's exact approach (embedding clustering from feedback)

3. **Measure**:
   - After accumulating 60+ labeled findings, enable the filter
   - Compare precision/recall vs baseline and vs judge-gate-only (ticket 92)
   - Track false suppression rate (findings that SHOULD have survived but didn't)

## Validation criteria

- [ ] Feedback capture mechanism works (findings stored in recall with correct type/labels)
- [ ] Filter suppresses findings similar to past-dismissed patterns
- [ ] Precision improves over judge-gate-only (ticket 92's result)
- [ ] False suppression rate <10% (real issues rarely match dismissed patterns)
- [ ] Cold-start path defined (what happens with <30 labeled findings?)

## Reject if

- Insufficient feedback volume (can't accumulate 60 labeled findings in reasonable time)
- Embedding similarity doesn't discriminate (dismissed and addressed findings look the same)
- recall's current embedding model lacks the resolution for this use case
- The improvement over ticket 92's judge-gate alone is <10% (not worth the complexity)

## Dependencies

- Ticket 92 (judge-gate baseline) — need precision/recall numbers to compare against
- recall ticket 36 (learnable preferences) — schema alignment for feedback storage

## Research informing design

- Greptile: universal LLM judge was "nearly random." Team-specific learned embeddings took
  acceptance 19% → 55%+. "Nits are subjective — definitions vary from team to team."
- CodeRabbit learnings: scoped per-repo or org-wide, usage tracking, approval workflow.
- Key insight: the problem is per-team calibration, not universal severity.

## References

- Research: `.scratch/research/judge-as-gate.md`, `.scratch/research/confidence-scoring.md`
- Greptile blog: https://www.greptile.com/blog/make-llms-shut-up
- recall ticket 36: `/home/sam/code/recall/.tickets/036-learnable-preferences.md`
