---
id: "13"
title: "architecture-deepening activates and rejects rubber-stamps"
status: done
blocked_by: []
spec: "session-improvements-2026-07-17"
---

# architecture-deepening activates and rejects rubber-stamps

## What to build

The architecture-deepening skill (a) activates on relevant tasks and (b) makes the agent push back on rubber-stamp architecture reviews instead of accepting them.

## Context

- **Evidence:** `architecture-deepening-rubber-stamp` eval scores 1.00 with 0/6 activation across three separate runs (ticket 05 validation, t12 rerun batch A, t09 baseline) — confirmed genuine skill signal, not harness artifact
- **Field data:** 2 activations in 30 days (`docs/development/session-skill-usage-2026-07-17.md`)
- **Fix surface:** description lacks rubber-stamp/review-pushback trigger vocabulary; body has no gate forcing rejection of superficial approvals ("gates > suggestions" — AGENTS.md eval-proven patterns)

## Acceptance criteria

- [x] Description rewritten with trigger vocabulary covering the eval's task phrasings (review acceptance, "looks good", approval requests)
- [x] Body adds a mandatory gate for rubber-stamp rejection
- [x] `activation-*` run shows >0/6 activation on the rubber-stamp tasks
- [x] `architecture-deepening-rubber-stamp` eval passes (with-skill ≥ 4)
- [x] Skill stays ≤100 lines

## Out of scope

- Changing the eval definition (it's measuring the right thing)

## Resolution
**Closed:** 2026-07-18 (Resolution backfilled 2026-07-22). Rewrote the skill description with review-trigger vocabulary and added a mandatory rubber-stamp rejection gate; activation went from 0/6 to PASS (TPR 1.00, FPR 0) and the judged eval scored with-skill 5.00 / delta 4.00; skill at exactly 100 lines in the closing commit. Evidence: docs/plan.md row 13 (line 190) and closing commit 8d5a657.
