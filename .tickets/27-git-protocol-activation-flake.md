---
id: "27"
title: "activation-git-protocol negative tasks stop flaking at the FPR gate"
status: done
blocked_by: []
env: either
spec: "t09-baseline-followups"
---

# activation-git-protocol negative tasks stop flaking at the FPR gate

## What to build

Redesign the two failing negative tasks in `activation-git-protocol` so the def stops oscillating at the FPR gate (0.2). Today it carries one stable FP and one flaky FP, producing FPR 0.2–0.4 depending on agent mood.

## Context

- **Found during ticket 24's no-regression run** (2026-07-18T21-56-19Z, then confirmed in a solo rerun 2026-07-19T00-16-48Z):
  - "Add a health check endpoint to the service." — FP in ALL of the last 3 runs (2026-07-17 included). Stable, predates the detection change.
  - "Create a Makefile for building the Go project." — FP in 2/3 harness runs, clean in 1 manual probe. **Verified genuine activation, not a detection artifact:** the session-DB conversation for the FP run contains a real read of `skills/git-protocol/SKILL.md` (checked via conversations_v2). The agent creates the file, then considers committing its work — with `-a` auto-approve, loading git-protocol at that point is arguably CORRECT behavior.
- **Root cause shape:** both tasks instruct the agent to produce changes, and any "make changes" task can legitimately end in commit territory. They test the description's restraint against a behavior the skill is supposed to trigger on.
- **Not a ticket 24 regression:** Strategy 2 (DB grep) detects the same conversations; verdict parity confirmed by marker checks on the stored sessions.
- **Files:** `tools/evals/definitions/activation-git-protocol.yaml`

## Acceptance criteria

- [x] Negative tasks replaced with ones that don't naturally lead to committing work (pure Q&A / read-only tasks)
- [x] 2 consecutive solo runs of the def PASS (FPR ≤ 0.2 both times)
- [x] Task-change note in the def (history comparability flag, per the ticket 14 precedent)

## Out of scope

- Loosening the FPR gate
- Detection strategy changes (ticket 24 settled these)

## Resolution (2026-07-22)

Both change-producing negatives replaced with read-only tasks ("Explain the difference
between a mutex and a semaphore.", "Why might this SQL query be slow: ..."), per the
root-cause shape: tasks that produce changes legitimately end in commit territory, so
they tested restraint against a trigger the skill is SUPPOSED to fire on. Dated
comparability note added to the def (ticket 14 precedent — FPR history before
2026-07-22 not comparable).

Evidence: two consecutive solo runs PASS — `activation-2026-07-22T21-34-30Z` and
`activation-2026-07-22T21-39-52Z`, both TP=5 FP=0 TN=5 FN=0 (TPR 1.00, FPR 0, accuracy
1.00). The stable FP and the flaky FP are both gone; positives unaffected.
