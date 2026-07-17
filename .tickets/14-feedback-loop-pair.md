---
id: "14"
title: "feedback-loop-debugging passes both of its effectiveness evals"
status: open
blocked_by: []
spec: "session-improvements-2026-07-17"
---

# feedback-loop-debugging passes both of its effectiveness evals

## What to build

Diagnose why `feedback-loop-effectiveness` (3.11 < 3.5) and `feedback-loop-tighten-effectiveness` (3.66 < 4) both fail, and fix the skill until both pass. This is the only skill with two failing evals.

## Context

- **History:** both evals failed pre-merge (2026-07-15 baseline) AND post-merge (t12 rerun) — the ticket-02 merge of troubleshooting-protocol into feedback-loop-debugging (commit 5cd6bb5) neither fixed nor regressed them
- **Hypothesis to test first:** did the merge dilute the protocol's imperative steps? Compare pre-merge skill content (git history) against session outputs in the failing runs' `outputs/` dirs
- **Judge transcripts:** `tools/evals/results/2026-07-17T00-58-49Z/outputs/` (and t09 baseline dir) show what the agent actually did with the skill loaded

## Acceptance criteria

- [ ] Root cause documented: content gap vs criteria mismatch vs merge dilution (read failing trial outputs, cite specifics)
- [ ] Skill fixed (or eval criteria corrected if they measure the wrong thing — record which)
- [ ] Both evals pass on a fresh run
- [ ] Skill stays ≤100 lines

## Out of scope

- Re-splitting troubleshooting-protocol back out (user decided merge in ticket 02)
