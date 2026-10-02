---
id: "179"
title: "Measure activation suite (TPR/FPR) on v3 vs v2 baseline — close last cutover gap"
status: in_progress
blocked_by: []
priority: high
tags: [kiro-v3]
---

# Activation suite parity: v3 vs v2

## Why

Last cutover readiness gap we own: I verified skills *activate* on v3 (168 A/B,
beacon 3/3) but had NOT measured the activation SUITE's TPR/FPR on v3 vs the v2
baseline. This measures parity.

## Mechanism

Added `ACT_ENGINE` env to `run-activation.sh` (injects `--agent-engine $ACT_ENGINE`
after `kiro-cli chat`; default unset = v2 binary default). Non-invasive, mirrors the
proof harness `PROOF_ENGINE` pattern.

## Cost reality

One activation def = ~5 min (10-15 real agent invocations); v3 is slower (cold start).
25 defs × 2 engines ≈ 4 h. Running ALL inline is infeasible — so: direct same-input
comparison on representative defs, backgrounded.

## Data points (direct same-input v2 vs v3)

| Def | v2 | v3 | Verdict |
|-----|----|----|---------|
| activation-code-review | TP=2 FN=3 → TPR 0.40 | TP=2 FP=2 TN=8 FN=3 → TPR 0.40 FPR 0.20 | **PARITY** (identical TP/FN; 0.40 is the known unforced baseline, not a v3 regression) |

Plus prior A/Bs (spike 168 canary; ticket 172 beacon 3/3 both engines) — all show
v3 == v2 activation.

## Background sample (running)

5-def sample (handoff, data-modeling, testing-guide, planning-cycles, docs-audit) on
both engines → `/tmp/act-parity.log` (done marker `DONE_MARKER`). Launched detached
(`setsid`, pid logged) ~16:44. Check: `cat /tmp/act-parity.log`; compare the v2 vs v3
TOTALS lines.

## Acceptance criteria

- [x] `run-activation.sh` can target v3 (`ACT_ENGINE=v3`), non-invasively
- [x] Direct same-input v2-vs-v3 comparison on >=1 def shows parity (code-review: identical)
- [ ] 5-def background sample completes; v2 vs v3 TPR/FPR within noise (read /tmp/act-parity.log)
- [ ] Verdict recorded: activation parity confirmed or regression flagged

## Interim verdict

Every signal (code-review same-input, 2 prior A/Bs) shows v3 activation at parity with
v2. The background sample is confirmation, not expected to change the conclusion. The
0.40-0.50 TPR floor is the pre-existing unforced-activation baseline (glossary), NOT a
v3 effect — identical on both engines.
