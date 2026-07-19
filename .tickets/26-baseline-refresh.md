---
id: "26"
title: "Eval baseline record reflects the post-baseline fix batch"
status: done
blocked_by: []
spec: "t09-baseline-followups"
---

# Eval baseline record reflects the post-baseline fix batch

## What to build

One fresh full suite run and an updated baseline record. The 2026-07-17 baseline (26/35 judged, 8 known gaps; 19/20 activation) is stale after tickets 13/14/19: three former failures now pass or are retired, and the regression rule ("any NEW failure outside the 8 known gaps") needs a new reference set.

## Context

- **Changes since baseline @ 24d9691:** architecture-deepening-rubber-stamp now passes (ticket 13); feedback-loop-effectiveness + feedback-loop-tighten-effectiveness now pass via bug-injected fixtures — pre-2026-07-18 history flagged non-comparable in the def (ticket 14); activation-recall retired (ticket 19); new def activation-architecture-deepening (passing)
- **Expected outcome:** judged ≥29/35 with ~5 remaining known gaps (was 8; verify each is still a genuine gap); activation 20/20 live defs
- **Use the new resume flag** if the run interrupts: `run.sh --all --skip-completed <dir>` (ticket 15)
- **Run discipline:** `setsid nohup`, no script edits mid-run, ~8-10h for the judged suite (eval-execution steering)
- **Files:** `docs/development/eval-baseline-2026-07-17.md` (record to supersede or amend), `tools/evals/definitions/` (known_gap frontmatter accounting)

## Acceptance criteria

- [x] Full judged suite + activation suite run at a recorded commit — judged `results/2026-07-19T00-29-50Z` @ 28ed513 (10.2h, 35 defs); activation `results/activation-2026-07-18T21-56-19Z` (200 tasks, post-ticket-24 detection)
- [x] Baseline record updated — successor written: `docs/development/eval-baseline-2026-07-19.md`. Judged 28/35 (80.0%, was 26/35); per-def deltas recorded (4 flipped to PASS incl. tickets 13/14 confirmations; 2 flipped to FAIL). Known gaps 8 → 5, each re-justified (small-model-code-edit and steering-pointer cleared; feedback-loop-tighten downgraded to flaky-at-threshold)
- [x] Regression rule restated — any NEW failure outside the 7 named failures is a regression; activation expect 19/20 until ticket 27
- [x] NEW unexplained failures triaged into a ticket — ticket 28 (agents-md-authoring 3.83/thr 4, handoff-decaying delta 0.67/thr 0.75 with the a03798e mid-merge confound, + feedback-loop-tighten oscillation)

## Resolution notes

- Expected ≥29/35, got 28/35: the two new near-threshold failures offset one expected gain. Both have positive deltas and prior PASSes — triage (ticket 28) decides flaky vs genuine before they count against the skills.
- Activation 19/20 (not the expected 20/20): git-protocol FPR flake, verified genuine agent skill-load, ticket 27.

## Out of scope

- Fixing failures found (separate tickets, like this batch)
