---
name: handoff
description: "End-of-session handoff — write a new HANDOFF.md capturing current state for the next session."
metadata:
  type: process
  invocation: user-only
---

Delete any existing `.scratch/HANDOFF.md`, then create a new one capturing everything the next session needs to continue this work.

## Format

```markdown
---
created_at: {ISO 8601 with offset}
base_commit: {git rev-parse --short HEAD}
handoff_key: {workstream-slug}
---

# Handoff

## Objective
What the receiving session should accomplish next.

## Task Graph Position
Where we are on docs/task-graph.md — completed tasks, current task, next on critical path.

## Mental Model
Key terms/decisions the next session must internalize before acting. Point to .memory/CONTEXT.md and highlight the 3-5 most important resolved terms for the current workstream.

## Constraints
- Rules, boundaries, things not to change
- Tool prerequisites (versions, auth, installed binaries)

## What Was Tried
Approaches attempted this session that didn't work, with brief reason why. Prevents repeated dead ends.

## Current State
- Files created/modified this session
- Proofs/evals run and their results
- Open issues filed or closed
- Unresolved design questions (if any)

## Next Steps
Ordered next actions (reference task IDs from docs/task-graph.md).

## Evidence
Pointers to spike results, test output, or research notes worth reading on demand.

## Available Prompts
List project prompts the next session can use: @handoff, @read-handoff, @grill-with-docs, @research-prior-art
```

## Rules
- Delete the old handoff first — new supersedes old for the same `handoff_key`
- `handoff_key`: use the current workstream (`bootstrap`, `proof-harness`, `eval-harness`, `skill-authoring`)
- `base_commit`: run `git rev-parse --short HEAD` at handoff time
- Be specific — file paths, task IDs, function names
- Point to evidence in `.scratch/`; do not paste logs
- Keep under 80 lines
- Always include "What Was Tried" even if empty ("Nothing failed this session")
