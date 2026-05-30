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

### Windows (PowerShell)

```powershell
# Launch in background, capture output
$proc = Start-Process -PassThru -NoNewWindow -FilePath "pwsh" -ArgumentList "-c", "<command>" -RedirectStandardOutput "$env:TEMP\task-output.log" -RedirectStandardError "$env:TEMP\task-error.log"

# Poll until done
while (!$proc.HasExited) { Start-Sleep 5 }

# Read results
Get-Content "$env:TEMP\task-output.log" -Tail 50
$proc.ExitCode
```

**How to observe:**
- `Get-Content "$env:TEMP\task-output.log" -Tail 20` — check progress
- `(Get-Item "$env:TEMP\task-output.log").Length` — is output growing?
- `$proc.HasExited` — check if still alive

### Linux/macOS (bash)

```bash
nohup <command> > /tmp/task-output.log 2>&1 &
while kill -0 $! 2>/dev/null; do sleep 5; done
tail -50 /tmp/task-output.log
```

### When to use

- Package installs (`npm install`, `pip install`, `cargo build`)
- Test suites that take >15s
- Data processing scripts
- Any command where timeout is a risk

**Report when done:** read the log, summarize outcome (pass/fail/output), clean up the log file.

