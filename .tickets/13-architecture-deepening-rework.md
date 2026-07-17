---
id: "13"
title: "architecture-deepening activates and rejects rubber-stamps"
status: open
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

- [ ] Description rewritten with trigger vocabulary covering the eval's task phrasings (review acceptance, "looks good", approval requests)
- [ ] Body adds a mandatory gate for rubber-stamp rejection
- [ ] `activation-*` run shows >0/6 activation on the rubber-stamp tasks
- [ ] `architecture-deepening-rubber-stamp` eval passes (with-skill ≥ 4)
- [ ] Skill stays ≤100 lines

## Out of scope

- Changing the eval definition (it's measuring the right thing)
