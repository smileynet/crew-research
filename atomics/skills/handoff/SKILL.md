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

```markdown
---
created_at: {ISO 8601 with offset}
base_commit: {short SHA}
handoff_key: {workstream-slug}
---

# Handoff

## Objective
## Constraints
## Prior Decisions
## Current State
## Next Steps
## Fog (if applicable)
## Evidence
```

**Current State:** Reference PLAN.md for work status rather than restating it. Capture only what the plan doesn't know: what you were mid-way through, what's in your head that isn't in a file yet. Never duplicate ticket status or task graph position — those live in the plan.

**Fog section:** If the project has a map (proposal-plan.md) or unresolved questions from a grill session, note what CANNOT yet be planned — decisions that surfaced but remain unclear. This tells the next session where the frontier is vs what's still in fog.

## Rules

- `handoff_key`: short slug for the workstream (e.g., `auth-flow`, `eval-harness`)
- Be specific — file paths, function names, task IDs
- Point to evidence; do not paste logs or transcripts
- Include what was TRIED and failed (prevents repeated dead ends)
- New handoff supersedes old for the same `handoff_key`
- **Decay prior work**: current phase = full detail; prior phase = one-line outcomes + decisions; 2+ phases ago = drop (unless it's a decision or constraint)

## Quality Check

Verify: (1) someone with NO context can continue, (2) next steps are actionable, (3) file paths are accurate.

## Promotion Check

Before finalizing, review the session for promotable artifacts:

1. **CONTEXT.md** — terms resolved or clarified? Add now.
2. **ADRs** — hard-to-reverse decisions made? → `.memory/adr/NNNN-slug.md`
3. **Promote scratch** — `.scratch/` artifacts future sessions need? → `.memory/specs/`
4. **Dead scratch** — obsolete `.scratch/` files? Note for cleanup.

## Artifact Update Nudge

Scan the session for findings that should propagate. Nudge when:
- A skill has a gap or stale instruction
- AGENTS.md commands/conventions changed
- A repeated manual process could be a tool script
- Technical findings belong in `.memory/specs/`
- New work surfaced → create a `.tickets/` entry
- Terms were used inconsistently → glossary update

Add a `## Recommended Updates` section (after Next Steps) if applicable:

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
