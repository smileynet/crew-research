---
id: "76"
title: "Make activation verdict tolerate decimal bc output"
status: done
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

- [x] Boolean comparisons work with both `1` and `1.00` output
- [x] Perfect activation metrics produce PASS on Windows and Unix
- [x] Harness checks or documents its `bc` dependency
- [x] Regression test covers decimal comparison output

## Resolution (2026-08-10)

Fixed. Replaced bash (( $(bc) )) with string comparison on cut -d. -f1 output. Works with both GNU bc (integer '1') and Windows shim (decimal '1.00'). Tested pass/fail/edge. bc dependency already documented in tool-installation skill.
