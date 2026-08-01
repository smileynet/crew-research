---
id: "76"
title: "Make activation verdict tolerate decimal bc output"
status: open
blocked_by: []
---

# Make activation verdict tolerate decimal bc output

## What to build

Make `tools/evals/harness/run-activation.sh` interpret any nonzero numeric
result from `bc` as true. The current arithmetic wrapper accepts GNU `bc`'s
integer `1` but rejects the Windows shim's valid decimal `1.00`, producing a
FAIL verdict after perfect TP/TN metrics.

Observed while validating ticket 75: TP=5, FP=0, TN=5, FN=0, followed by
`invalid arithmetic operator (error token is ".00 ")`.

## Acceptance criteria

- [ ] Boolean comparisons work with both `1` and `1.00` output
- [ ] Perfect activation metrics produce PASS on Windows and Unix
- [ ] Harness checks or documents its `bc` dependency
- [ ] Regression test covers decimal comparison output
