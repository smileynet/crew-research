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

## Constraints
Rules, boundaries, or things not to change.

## Prior Decisions
Choices made this session with brief rationale. Include rejected paths only when they prevent repeated dead ends.

## Current State
- Files created/modified this session
- Proofs/evals run and their results
- Open issues filed or closed

## Next Steps
Ordered next actions (reference task IDs from docs/task-graph.md).

## Evidence
Pointers to spike results, test output, or research notes worth reading on demand.
```

## Rules
- Delete the old handoff first — new supersedes old for the same `handoff_key`
- `handoff_key`: use the current workstream (`bootstrap`, `proof-harness`, `eval-harness`, `skill-authoring`)
- `base_commit`: run `git rev-parse --short HEAD` at handoff time
- Be specific — file paths, task IDs, function names
- Point to evidence in `.scratch/`; do not paste logs
- Keep under 60 lines
