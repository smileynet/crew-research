---
name: handoff
description: "End-of-session handoff that captures current state for the next session. Use when ending a work session, switching context, or before a long break."
metadata:
  type: process
  invocation: user-only
  practice: null
  params:
    ephemeral_path: ".scratch"
    handoff_file: "HANDOFF.md"
    glossary_path: ".memory/CONTEXT.md"
---

# Handoff

Write a handoff document that lets the next session continue without re-discovery.

## Workflow

1. Delete any existing `{{params.ephemeral_path}}/{{params.handoff_file}}`
2. Run `git rev-parse --short HEAD` to get base_commit
3. Write the new handoff file with all required sections
4. Keep under 60 lines — dense, not verbose

## Required Sections

The handoff is the **volatile delta** on top of durable layers — never a mirror of them. Each layer owns one thing: the tracker (`.tickets/`) owns status/deps/ACs, the persistent store (recall/ADR/specs) owns durable decisions + why, and the handoff owns ONLY volatile in-flight state + the next action. Point, don't paste.

```markdown
---
created_at: {ISO 8601 with offset}
base_commit: {short SHA}
handoff_key: {workstream-slug}
in_flight_ticket: {NN or "none"}
---

# Handoff

## Focus
## In-Flight
## Fog (if applicable)
## Constraints
## Pointers (if applicable)
## Recommended Updates (if applicable)
```

**Focus:** One-sentence workstream objective. Do NOT recap per-ticket status — derivable from `tkt ready` + `in_flight_ticket`.

**In-Flight:** The delta ONLY — what the durable layers don't know: uncommitted/mid-edit work, in-head findings not yet in a file, why-this-approach, dead-ends tried. NOT the ticket roster, NOT "working tree clean".

**Fog:** Un-ticketable interpretive questions — decisions that surfaced but remain unclear (a ticketable question is a ticket). Tells the next session where the frontier is vs what's still fog.

**Constraints:** Session-live env facts that block the NEXT step (tool versions, env vars, platform quirks). Strongest-earning — omit constraints that don't bear on what's next.

**Pointers:** Terse spec/ADR/file paths to read next. Do NOT paste a commit list (`base_commit..HEAD` is derivable). Durable decisions live in recall/ADR — point, don't restate.

**`in_flight_ticket` frontmatter:** id of the ticket in progress (or `"none"`). Replaces the old roster — ephemeral, operator-owned, not a `.tickets/` contract field.

## Rules

- `handoff_key`: short slug for the workstream (e.g., `auth-flow`, `eval-harness`)
- Be specific — file paths, function names, task IDs
- Point to evidence; do not paste logs or transcripts
- Include what was TRIED and failed (prevents repeated dead ends)
- New handoff supersedes old for the same `handoff_key`
- **Decay prior work**: current phase = full detail; prior phase = one-line outcomes + decisions; 2+ phases ago = drop (unless it's a decision or constraint)

## Quality Check

Verify: (1) someone with NO context can continue, (2) `in_flight_ticket` points to real in-progress work (or "none"), (3) file paths are accurate.

## Promotion Check

Before finalizing, review the session for promotable artifacts:

1. **CONTEXT.md** — new term that needs disambiguation? (Test: could two people mean different things by this word?) Add it. Do NOT add gotchas, implementation details, or decisions here — those go to AGENTS.md Constraints or ADRs.
2. **ADRs** — hard-to-reverse decisions made? → `.memory/adr/NNNN-slug.md`
3. **Promote scratch** — `.scratch/` artifacts future sessions need? → `.memory/specs/`
4. **Dead scratch** — obsolete `.scratch/` files? Note for cleanup.
5. **Plan sync** — if tickets were closed this session, run `tkt sync-plan --check` to verify plan.md reflects reality.

## Artifact Update Nudge

Scan for findings that should propagate: skill gaps, AGENTS.md changes, repeatable processes (→ script), technical findings (→ `.memory/specs/`), new work (→ ticket), inconsistent terms (→ glossary).

Add a `## Recommended Updates` section if applicable:

```markdown
## Recommended Updates
- [ ] skill(foo): add X — we hit this gap during Y
- [ ] AGENTS.md: add `mise run bar` to Commands
- [ ] .tickets/NN-slug.md: new ticket for Z (out of scope this session)
```

Skip if the session produced no artifact-worthy findings.

## Recall Write-Back (if available)

If `recall` is on PATH, persist qualifying decisions:

```bash
recall add "decided X because Y" --room decisions --type decision
```

Qualifies if: hard-to-reverse OR matters beyond next session. Don't persist file paths or implementation details (those are in HANDOFF.md).
