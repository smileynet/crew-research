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

## Gather (internal — do not report raw)

0. If `recall` is on PATH, run `recall prime` — internalize silently
1. Read `{{params.ephemeral_path}}/{{params.handoff_file}}`
2. Read `{{params.glossary_path}}` (internalize key terms)
3. Check staleness: `git log --oneline {base_commit}..HEAD`
4. If `proposal-plan.md` exists, read it for project map
5. If task graph position is unclear, read `docs/plan.md`
6. If `.tickets/` exists, scan for frontier (open tickets with all blockers done)

Internalize all of this. The briefing you present is a distillation, not a dump.

## Briefing (present to user)

**Objective** — What we're building or doing, in one sentence.

**Progress** — Where we are. What's done, what phase we're in. If the repo moved since the handoff, summarize what landed. Write as narrative, not a status table.

**Unresolved** — Things we don't have answers to yet. Open questions, untested assumptions, unknowns that block confident decisions. Plain language — no internal labels or commit refs.

**Heads up** — Anything the user should be aware of before we proceed. Prior approaches that failed (and what we'll try differently), environmental quirks, risks to the proposed next step. Only include if there's something worth flagging — skip this section if everything is straightforward.

**Open tasks** — What's on the board. Numbered list from tickets, plan, or handoff next-steps. Keep to actionable items, not background work.

**Next step** — A specific, concrete proposal: "I'll [do X]. Proceed?" Don't ask what to do — propose and offer to start.

## What stays internal (never report to user)

- Handoff key and staleness count
- Raw constraints (tool versions, env vars) — only surface if they block the next step
- Dead ends and failed approaches — only mention if it changes direction ("X didn't work, so I'll try Y")
- Evidence file paths — read them for context, don't cite them
- Validation run mechanics — report results under Progress, not the commands

## Staleness Check (internal)

Before proposing next step, assess silently:
- Same blocker as last session? → approach is wrong, not effort
- "Next steps" unchanged for 2+ sessions? → rewrite plan from current state
- Estimates proven wrong by 3x+? → assumptions were wrong

If 2+ are true → trigger `vertical-slice-planning` before proceeding. Mention this in the briefing as "I think we need to re-plan before continuing" rather than citing the rule.

## Validation Run

If the project has a test suite or validation script:
1. Run it silently
2. Report pass/fail under Progress
3. Note regressions under Heads up

## Rules

- Treat the handoff as point-in-time state, not durable truth
- When in doubt, verify against the actual repo
- Do NOT start working until the briefing is delivered
- Write in plain language — no jargon, no internal labels
- The user resumed to make progress. End with momentum, not questions.
