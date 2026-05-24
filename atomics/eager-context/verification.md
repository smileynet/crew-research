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
