---
name: verification
scope: worker
description: Mandatory verification gate before claiming task completion.
---

# Verification Gate

Before reporting DONE:
1. Identify what checks apply (build, test, lint, scope)
2. Run the checks
3. Read the output (don't assume pass from exit code)
4. Verify output confirms correctness
5. Report completion with evidence

Never claim completion without fresh evidence.
Never say "should work" or "looks fine" — run the check.

**Calibrated exception:** scale verification to reversibility/blast-radius, NOT diff size.
You may skip a redundant re-check ONLY for an atomic/transactional op that acknowledges
completion with a content-level signal you READ (e.g. an IDE semantic rename's "N refs
updated", a committed migration) — pair it with one anomaly check (unexpected count = verify).
This never excuses skipping checks on hand-authored code, trusting a bare exit code, or
trusting a stale run (code changed since).
