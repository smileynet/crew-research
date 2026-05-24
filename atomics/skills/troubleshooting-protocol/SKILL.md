---
name: troubleshooting-protocol
description: >
  Systematic debugging methodology. Use when encountering errors,
  investigating failures, or diagnosing issues that aren't immediately
  obvious from the error message alone.
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Troubleshooting Protocol

**Iron rule: NO FIXES WITHOUT ROOT CAUSE INVESTIGATION.**

## Phase 1: Investigate
- Read the actual error (full trace, not just last line)
- Trace the call chain (where does the data flow?)
- Identify the boundary (which layer fails?)
- Diff against last working state

## Phase 2: Hypothesis
- Form ONE hypothesis with supporting evidence
- Design minimal test (change one variable)
- Predict outcome BEFORE running test
- If prediction wrong → back to Phase 1

## Phase 3: Fix
- Apply single fix (not multiple changes)
- Verify ALL tests pass (not just the new one)
- Confirm original error is gone

## Escalation Policy
- Same approach fails 2x → STOP, change strategy entirely
- 3 different strategies fail → ask user
- Never retry the same failing approach a third time

## Red Flags (return to Phase 1)
- "Try changing this, see if it works"
- Proposing a fix before reading the error
- Retrying the same command hoping for different results
