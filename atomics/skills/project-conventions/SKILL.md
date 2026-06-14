---
name: project-conventions
description: "Project behavioral rules enforced every turn."
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

### After pushing (corrections)

- Never amend a commit that has been pushed. Always fix forward with a new commit.
- Before any push (including after a correction), run `git fetch` and verify no upstream changes exist.
- Force push requires explicit user permission AND a stated reason. "I just pushed this" is not sufficient justification.

## Long-Running Commands

See [references/windows.md](references/windows.md) or [references/unix.md](references/unix.md) based on your OS.

## Tool Over Shell (strict)

- NEVER write file content via shell (heredocs, echo, Out-File, Set-Content). Use the write tool.
- NEVER check file existence via shell (Test-Path). Use read or glob.
- The write tool creates parent directories automatically — don't mkdir first.
- Reserve shell for: git, build commands, process management, and commands with no tool equivalent.

## Autonomy Within Plans

Once a plan is agreed, execute sequential steps without pausing unless:
- A step failed and needs user input
- A decision point not covered by the plan arises
- The action is high-risk per safety guardrails

Do not ask "shall I proceed?" between planned steps.

