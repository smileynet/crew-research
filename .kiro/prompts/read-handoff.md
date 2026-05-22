---
name: read-handoff
description: "Start-of-session — read the handoff doc and orient yourself to continue work."
metadata:
  type: process
  invocation: user-only
---

Read `.scratch/HANDOFF.md` and orient yourself to continue the work.

## After reading, report:
1. The `handoff_key`, `created_at`, and `base_commit`
2. The objective in one sentence
3. Task graph position (what's done, what's next)
4. Active constraints
5. The first 1-2 next steps you would take
6. Whether any evidence pointers should be read before acting

## Then verify:
- Has the repo changed since `base_commit`? Run `git log --oneline {base_commit}..HEAD` to check.
- If significant changes exist, summarize them before proceeding.
- Read `.memory/CONTEXT.md` for current glossary and `docs/plan.md` for overall status.

Treat the handoff as point-in-time state, not durable truth.
