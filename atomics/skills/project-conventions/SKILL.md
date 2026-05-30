---
name: project-conventions
description: "Workspace behavioral rules enforced every turn."
metadata:
  type: reference
  invocation: agent-only
---

# Project Conventions (Always Enforce)

## Glossary Maintenance

Update `.memory/CONTEXT.md` immediately when a term is resolved or clarified. Don't batch — capture as it happens.

**Format:**
```
**Term**:
One-sentence definition.
_Avoid_: what not to call it
```

**What qualifies as a term:**
- Domain concepts (what the project calls things)
- Internal naming decisions (why we say X not Y)
- Abbreviations and acronyms in the codebase
- Anything where two people might use different words for the same thing

**What doesn't belong:** implementation details, specs, decisions with rationale (those are ADRs).

If CONTEXT.md doesn't exist, create it on first term resolution.

## Document Placement
- Default new documents to `.scratch/` (ephemeral)
- Only place in `.memory/` if a future session will need it
- Only place in `docs/` when explicitly requested for user-facing publication
- Never accumulate scratch — promote or delete

## Session Discipline
- Read before writing — check existing code/docs before creating new ones
- Don't ask questions the codebase can answer — explore first

## Git Discipline
- If no git repo exists, run `git init` and make an initial commit before starting work
- Commit after each logical unit of work — don't accumulate uncommitted changes
- Push after committing (if remote exists)
- Use descriptive commit messages: `type(scope): what changed`

## Long-Running Commands

When a command may take >15 seconds (builds, tests, installs, data processing):

```bash
# Launch in background, capture output
nohup <command> > /tmp/task-output.log 2>&1 &

# Poll until done
while kill -0 $! 2>/dev/null; do sleep 5; done

# Read results
tail -50 /tmp/task-output.log
```

**When to use this pattern:**
- Package installs (`npm install`, `pip install`, `cargo build`)
- Test suites that take >15s
- Data processing scripts
- Any command where timeout is a risk

**How to observe:**
- `tail -20 /tmp/task-output.log` — check progress
- `wc -l /tmp/task-output.log` — is output growing?
- `kill -0 $! 2>/dev/null && echo running || echo done` — check if still alive

**Report when done:** read the log, summarize outcome (pass/fail/output), clean up the log file.

