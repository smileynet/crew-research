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

## Validation Contract

Scripts and tools that produce output SHOULD return structured results:
- JSON: `{"status": "pass|fail|error", "metrics": {...}, "errors": [...]}`
- Exit code: 0=pass, 1=fail, 2=crash
- Self-validate output (count checks, schema validation, range checks)

## Git Discipline
- If no git repo exists, run `git init` and make an initial commit before starting work
- Commit after each logical unit of work — don't accumulate uncommitted changes
- Push after committing (if remote exists)
- Use descriptive commit messages: `type(scope): what changed`

### When push is rejected (upstream changes)

1. Run `git fetch` then `git log --oneline HEAD..origin/main` to see what's new
2. **If fast-forwardable** (our commits are ahead, theirs don't conflict): tell the user "upstream has N new commits, can fast-forward merge — safe to pull and push"
3. **If diverged** (both sides have commits): tell the user what the upstream commits are, whether conflicts are likely (check `git merge --no-commit --no-ff origin/main` then `git merge --abort`), and ask how they want to proceed (merge vs rebase)
4. Never force-push or auto-rebase without telling the user what happened upstream

## Long-Running Commands

When a command may take >15 seconds (builds, tests, installs, data processing):

### Windows (PowerShell)

```powershell
# LAUNCH: fire-and-forget with log capture (returns immediately)
Start-Process -WindowStyle Hidden -FilePath "pwsh" -ArgumentList "-c", "<command>" -RedirectStandardOutput "$env:TEMP\task-output.log" -RedirectStandardError "$env:TEMP\task-error.log"

# OBSERVE (separate command, after sleeping):
Start-Sleep 15
Get-Content "$env:TEMP\task-output.log" -Tail 20
Get-Content "$env:TEMP\task-error.log" -Tail 20
```

**Anti-patterns (NEVER do these):**
- `Start-Process -NoNewWindow -RedirectStandardOutput` — **BLOCKS** until child exits. The child shares the parent console and pipe handles prevent return.
- Wrapping `Start-Process` inside `pwsh -File` or `pwsh -Command` — nested shell waits for its children, blocking the agent.

**Why `-WindowStyle Hidden` works:** Creates a separate hidden console window. The child process is fully detached from the parent's console handles, so the parent returns immediately.

**How to observe:**
- `Get-Content "$env:TEMP\task-output.log" -Tail 20` — check progress
- `(Get-Item "$env:TEMP\task-output.log").Length` — is output growing?
- `netstat -ano | findstr ":PORT.*LISTENING"` — check if server is up

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
- Starting services (ComfyUI, dev servers, etc.)
- Any command where timeout is a risk

**Report when done:** read the log, summarize outcome (pass/fail/output), clean up the log file.

