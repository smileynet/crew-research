---
id: "115"
title: "Re-run effectiveness-project-cleanup eval after gate strengthening"
status: open
blocked_by: ["114"]
priority: high
---

# Re-run effectiveness-project-cleanup eval after gate strengthening

## Intent source

Eval run 2026-08-19T00-13-57Z: effectiveness-project-cleanup FAILED threshold (2.83 < 3.5) but passed delta (1.33 ≥ 1.0). Root cause analysis shows:
1. Task 1 trial 3 scored 1 due to rate limit + tool approval error (infra noise, not skill quality)
2. The disambiguation gate instructions were too general — strengthened in follow-up commit
3. Judge panel was degraded (n=2, codex+agy only — kiro excluded from judging its own output)

## What to build

Re-run the eval after the gate-strengthening fix lands and verify:
- Task 1 (CONTEXT.md gate-only) score improves from 2.33 → 3.5+
- No infra failures (rate limits, tool approval) — retry or exclude those trials
- Overall with-skill score crosses 3.5 threshold

If still failing after fix: examine trial outputs to identify which specific gate applications the agent gets wrong, and propose further skill tightening.

## Acceptance criteria

- [ ] Eval re-run completes without infra errors
- [ ] Task 1 avg score ≥ 3.0 (up from 2.33)
- [ ] Overall with-skill score ≥ 3.5 (threshold pass)
- [ ] Or: if threshold still missed, findings document identifies exactly what the agent gets wrong with proposed fix

## Out of scope

- Changing the eval criteria or fixture (keep the same for comparison)
- Running the full eval suite
