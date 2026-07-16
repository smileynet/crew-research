---
name: read-handoff
description: "Start-of-session orientation — read the handoff and continue work. Use when starting a new session, resuming after a break, or picking up someone else's work."
metadata:
  type: process
  invocation: user-only
  practice: null
  params:
    ephemeral_path: ".scratch"
    handoff_file: "HANDOFF.md"
    glossary_path: ".memory/CONTEXT.md"
---

# Read Handoff

Orient yourself to continue work from where the last session left off.

## Workflow

0. If `recall` is on PATH, run `recall prime` — internalize as background context (do not repeat to user)
1. Read `{{params.ephemeral_path}}/{{params.handoff_file}}`
2. Read `{{params.glossary_path}}` (internalize key terms)
3. Check staleness: `git log --oneline {base_commit}..HEAD`
4. If `proposal-plan.md` exists, read it — this is the project map (destination, decisions, fog, scope)
5. If task graph position is unclear, read `docs/plan.md`
6. If `.specs/tickets/` exists, scan for frontier (open tickets with all blockers done)

## Report After Reading

1. **Handoff key** and how stale it is (commits since base_commit)
2. **Objective** in one sentence
3. **Task graph position** — what's done, what's next
4. **Frontier** — what's actionable now (from map or next steps)
5. **Fog** — what's known-unknown (from handoff fog section or map)
6. **Constraints** — especially tool prerequisites
7. **What was tried** — acknowledge dead ends
8. **Proposed next action** — state what you'd do first and offer to start. Be specific: "I'll [concrete action]. Want me to proceed?" Don't ask "what would you like to do?" — the user came back to continue, not to re-plan.
9. **Non-obvious** — any gotchas, environmental quirks, or constraints not captured in the handoff itself

## Verify Before Acting

- Has the repo changed since `base_commit`? Summarize if yes.
- Are required tools available?
- Are there unresolved design questions?
- Do you need to read any evidence files?

## Staleness Check

Before proceeding, assess:
- Same blocker as last session? → approach is wrong, not effort
- "Next steps" unchanged for 2+ sessions? → rewrite plan from current state
- Estimates proven wrong by 3x+? → assumptions were wrong

If 2+ are true → trigger `vertical-slice-planning` before proceeding.

## Validation Run

If the project has a test suite or validation script:
1. Run it. Report current pass/fail count.
2. Note any regressions since last session.
3. State today's target: which specific test/assertion to make green.

## Rules

- Treat the handoff as point-in-time state, not durable truth
- When in doubt, verify against the actual repo
- Do NOT start working until orientation is reported
- End with a proposed action, not a question. The user resumed to make progress — propose the next step and offer to start.
