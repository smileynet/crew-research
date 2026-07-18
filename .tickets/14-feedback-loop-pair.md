---
id: "14"
title: "feedback-loop-debugging passes both of its effectiveness evals"
status: done
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

## Root Cause (2026-07-18)

**Verdict: fixture-task mismatch (primary) + one small content gap (secondary). Merge-dilution hypothesis REJECTED** — the failure shape is identical pre/post-merge because it never depended on skill content.

**feedback-loop-effectiveness (2.66):** tasks 1 and 2 described bugs that do not exist in the pristine `defu` fixture. Verified empirically against upstream main: `defu(null, {a:1})` returns `{a:1}` (no TypeError), and `defu({a:[1,2]}, {a:[3,4]})` returns `{a:[1,2,3,4]}` (documented concat), not the claimed `{a:[3,4]}`. Task scores: task0 4.33 (passes), task1 1.33 [0,2,2], task2 2.33 [3,0,4]. The score-0 trials are 180s timeouts — trial outputs (`2026-07-17T10-41-09Z/outputs/feedback-loop-effectiveness-with-skill-task1-trial1.txt`, cut off mid-sentence at 941 lines) show agents correctly building reproductions, failing to make them go red (impossible), then theorizing in circles. The skill WORKED — agents refused to fix without reproduction — but judge criteria assume a fixable bug, capping honest scores at ~2. Baseline agents guessed fixes and scored similarly low, masking the delta.

**Fix:** injected real bugs via new per-task fixtures (`defu-null-bug`: seedless reduce → real TypeError; `defu-nested-arrays-bug[-with-test]`: nested array concat skipped, suite stays green). Harness gained per-task `fixture:` override (backwards-compatible). Task wordings updated to match the real bugs; criteria unchanged in spirit. Pre-2026-07-18 history for this def measured an impossible task — not longitudinally comparable (noted in def header).

**feedback-loop-tighten-effectiveness (3.88 vs 4):** only task1 (memory leak) dragged (3.33). Trial outputs measure and accelerate but never state a numeric PASS/FAIL criterion or the baseline → ONE change → re-measure differential structure. The skill body was red/green-centric; continuous-metric signals were uncovered. Fix: added continuous-signal loop guidance to SKILL.md (92 lines).
