---
name: project-cleanup
description: "End-of-session orchestrator — consolidate knowledge artifacts, enforce role conformance, sync tickets, and prepare for handoff. Dispatches subagents for unbiased CONTEXT.md and AGENTS.md review. Use before handoff, when the project feels cluttered, or periodically. Trigger: clean up, wrap up, project cleanup, end of session, before handoff, consolidate, tidy up, is everything in order."
metadata:
  type: process
  invocation: both
  practice: null
---

# Project Cleanup

End-of-session orchestrator. Detect what needs attention, fix what's mechanical, dispatch subagents for unbiased review, create tickets for the rest.

## When to Run

- Before `/handoff` (the standard pre-handoff ritual)
- When the project feels cluttered
- After a long session that created/modified knowledge artifacts
- Periodically (weekly or at session start if drift suspected)

## Process

### 1. Auto-detect (fast, inline)

Scan the project. Only phases with findings run:

| Check | Trigger | Phase |
|-------|---------|-------|
| `.scratch/` has files besides HANDOFF.md | stale scratch | 2 |
| CONTEXT.md >30 entries OR entries >3 lines with instructions | glossary bloat | 3 (subagent) |
| AGENTS.md >150 lines OR has `_Avoid_` patterns | role violation | 4 (subagent) |
| `.tickets/` exists | ticket drift | 5 |
| Session had corrections or new knowledge | guidance capture | 6 |

Report what was detected, skip phases with no findings.

### 2. Promote/delete scratch

- Promote lasting findings → `.memory/` (specs, ADRs per routing table)
- Delete completed handoffs, stale plans, one-time notes
- Keep only current HANDOFF.md and active working files

### 3. CONTEXT.md review (dispatch subagent)

Dispatch a fresh subagent — the working session's context is biased. The subagent must apply this exact test to EVERY entry:

> "Does this entry resolve WHICH MEANING we use for an ambiguous word?"
> YES (it disambiguates) → keep (trim to ≤3 lines: term + definition + _Avoid_)
> NO (it describes HOW something works, even if the word is ambiguous) → route:
> gotcha/env fact → AGENTS.md Constraints, spec/implementation → .memory/specs/, decision → ADR or delete, stale → delete

If the file is small (<20 entries, all ≤3 lines): apply the gate directly instead of dispatching. See [subagent prompts](references/subagent-prompts.md) for the dispatch template.

Integrate staged content (`.scratch/context-cleanup/move-to-agents.md`) into AGENTS.md Constraints after review.

### 4. AGENTS.md review (dispatch subagent)

Dispatch a fresh subagent:

> "Read AGENTS.md. Check: (1) no term+_Avoid_ patterns (→ CONTEXT.md), (2) no inline content >10 lines without a link (→ extract to .memory/specs/), (3) total ≤150 lines, (4) commands still work. Report findings with proposed fixes."

Apply fixes or create a ticket if AGENTS.md needs major restructuring (→ `/agents-md-authoring`).

### 5. Ticket sync

```bash
tkt sync-plan --check --brief
```

If findings: run `/plan-ticket-sync` process (audit tickets, create missing ones, fix ordering).

### 6. Guidance capture

Run guidance-sync probes P1-P4 inline (corrections, friction, new knowledge, repetition). Apply trivial fixes directly. Propose non-trivial changes for user decision.

### 7. Verify + report

```bash
tkt validate --brief          # structural health
tkt sync-plan --check --brief # plan agreement (should pass now)
```

Present summary: what was fixed, what was ticketed, what needs user decision. Recommend `/handoff` to close the session.

## Subagent Dispatch

Use subagents for CONTEXT.md and AGENTS.md review — the working session normalized misplaced content and won't catch it. Small prompt + file-reading = high reliability per subagent-reliability steering.

## Does NOT

- Write the handoff (that's `/handoff` — recommend it after cleanup)
- Decompose new work into tickets (that's `/ticket-planning`)
- Rewrite README from scratch (recommend `/readme-writing` if stale)
- Audit user-facing docs quality (that's `/docs-audit`)

## References

- [Phase checklist](references/phase-checklist.md) — detailed per-check items
- [Subagent prompts](references/subagent-prompts.md) — dispatch templates
