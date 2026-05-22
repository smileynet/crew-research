---
name: read-handoff
description: "Start-of-session — read the handoff doc and orient yourself to continue work."
metadata:
  type: process
  invocation: user-only
---

Read `.scratch/HANDOFF.md` and orient yourself to continue the work.

## Orientation Sequence

1. Read `.scratch/HANDOFF.md`
2. Read `.memory/CONTEXT.md` (glossary — internalize key terms)
3. Check staleness: `git log --oneline {base_commit}..HEAD`
4. Read `docs/plan.md` if task graph position is unclear

## Report After Reading

1. **Handoff key** and how stale it is (commits since base_commit)
2. **Objective** in one sentence
3. **Task graph position** — what's done, what's next
4. **Mental model** — confirm you understand the key terms for this workstream
5. **Constraints** — especially tool prerequisites (verify they're available)
6. **What was tried** — acknowledge dead ends to avoid repeating them
7. **First 1-2 next steps** you would take

## Verify Before Acting

- Has the repo changed since `base_commit`? If yes, summarize changes.
- Are required tools available? (`yq`, `kiro-cli`, `claude` — check versions)
- Are there unresolved design questions flagged in the handoff?
- Do you need to read any evidence files before starting?

## Available Prompts

After orienting, these prompts are available:
- `@grill-with-docs` — design interrogation session
- `@research-prior-art` — research reference repos to inform a decision
- `@handoff` — write end-of-session handoff

Treat the handoff as point-in-time state, not durable truth. When in doubt, verify against the actual repo.
