---
name: project-conventions
description: "Workspace conventions enforced every turn: glossary upkeep, document placement (.scratch vs .memory vs docs), validation contract for scripts, and git discipline for convention projects."
metadata:
  type: reference
  invocation: agent-only
  practice: null
---

# Project Conventions (Always Enforce)

## Glossary Maintenance

Update `.memory/CONTEXT.md` immediately when a term is resolved or clarified. Don't batch — capture as it happens. Create the file on first term resolution if missing.

**Format:**
```
**Term**:
One-sentence definition.
_Avoid_: what not to call it
```

**What qualifies:** domain concepts, internal naming decisions, abbreviations/acronyms, anything where two people might use different words for the same thing.

**What doesn't belong:** implementation details, specs, decisions with rationale (those are ADRs).

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

In projects using these conventions, **proactive commits are authorized**: commit after each logical unit of work with `type(scope): what changed` messages, and push after committing (if a remote exists). This convention overrides the ask-first default for commits. If no git repo exists, `git init` and make an initial commit before starting work.

Before any push, run `git fetch` and verify no upstream changes exist.

### When push is rejected (upstream changes)

1. Run `git fetch` then `git log --oneline HEAD..origin/main` to see what's new
2. **If fast-forwardable** (our commits are ahead, theirs don't conflict): tell the user "upstream has N new commits, can fast-forward merge — safe to pull and push"
3. **If diverged** (both sides have commits): tell the user what the upstream commits are and whether conflicts are likely (check `git merge --no-commit --no-ff origin/main` then `git merge --abort`). **Default: rebase when possible** (clean merge test + local commits are few) — report what was rebased. Fall back to asking only when the rebase would be messy (conflicts, many local commits, shared branch)
4. Never force-push or auto-rebase without telling the user what happened upstream

## Long-Running Commands

On Unix: `nohup <command> > /tmp/output.log 2>&1 &`, then observe with `kill -0 $!` and `tail /tmp/output.log`. If the command must outlive this session, prefix with `setsid`. On Windows, see [references/windows.md](references/windows.md) for Start-Process rules.

## Missing Tools

When a command fails with "not found", install the tool for your OS immediately, verify it works, then continue. Project-level steering may provide a project-specific install guide.

## Tool Use Notes

- The write tool creates parent directories automatically — don't mkdir first.
- Never check file existence via shell (`test`, `Test-Path`) — use read or glob.
