---
id: "92"
title: "Spike: judge-as-gate verification for dispatch-codex-review"
status: open
blocked_by: []
env: either
spec: "eval-harness"
---

# Spike: Judge-as-Gate for dispatch-codex-review

## Hypothesis

Adding a cross-model verification pass after Codex generates review findings — where Claude
independently assesses each finding — will reduce false positives without significantly
reducing true positives. The architecture is already cross-model; this makes verification
explicit and measured.

## Baseline to measure against

1. **Current state**: Codex generates findings → filed as ticket or reported clean. No
   verification pass. No filtering.
2. **Baseline measurement**: Run dispatch-codex-review on 5 recent PRs/diffs. Manually
   classify each finding as: ✅ True positive, ⚠️ Nit, ❌ False positive.
   Industry baseline: ~19% useful, ~79% nits, ~2% incorrect (Greptile's figures).

## Spike design

1. After Codex generates findings, extract each as structured item.
2. For each finding, construct a verification prompt for the judge (different model family).
3. Apply threshold: only findings where judge rates ≥70 confidence survive.
4. Log all suppressed findings for audit.
5. Compare filtered output against baseline on the same PRs.

## Validation criteria

- [ ] Precision improves ≥20% over baseline (more findings are actually useful)
- [ ] Recall stays ≥80% (don't suppress more than 20% of real issues)
- [ ] At least 50% of suppressed findings are correctly suppressed (nits or false positives)
- [ ] End-to-end latency increase <2× baseline
- [ ] Suppressed findings logged and auditable

## Reject if

- Judge suppresses >30% of true positives
- Same-family judging shows no improvement (validates Greptile's "nearly random" finding)
- Latency makes the tool impractical (>10min per review)

## Research informing design

- Greptile: LLM severity scoring of own output was "nearly random"
- RoPoLL: 3-judge panel optimal; 2 models (Codex + Claude) is what we have
- OpenAI: "Verification is cheaper than generation"
- Anti-pattern: same model as both generator and judge (shared blind spots)

## References

- Research: `.scratch/research/judge-as-gate.md`
- dispatch-codex-review skill: `~/.kiro/skills/dispatch-codex-review/SKILL.md`
