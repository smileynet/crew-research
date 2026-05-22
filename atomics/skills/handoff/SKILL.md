---
name: handoff
description: >
  End-of-session handoff that captures current state for the next session.
  Use when ending a work session, switching context, or before a long break.
metadata:
  type: process
  invocation: user-only
  practice: null
  params:
    ephemeral_path: ".scratch"
    handoff_file: "HANDOFF.md"
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
## Evidence
```

## Rules

- `handoff_key`: short slug for the workstream (e.g., `auth-flow`, `eval-harness`)
- Be specific — file paths, function names, task IDs
- Point to evidence; do not paste logs or transcripts
- Include what was TRIED and failed (prevents repeated dead ends)
- New handoff supersedes old for the same `handoff_key`

## Quality Check

Before writing, verify:
- Could someone with NO context continue from this handoff?
- Are next steps actionable (not "finish the work")?
- Are file paths accurate (not guessed)?
