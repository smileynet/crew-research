---
name: code-review
description: "Code review standards and checklist. Use when reviewing code, PRs, or implementations for correctness, security, and quality."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Code Review

## Process

Two-axis review: **Standards** (is the code good?) and **Spec** (does it match intent?).

### 1. Gather the diff

```bash
git diff main          # or git diff HEAD~1, or the relevant range
```

### 2. Identify sources for each axis

**Standards axis:**
- Project rules from `.kiro/steering/` or `CONTRIBUTING.md`
- Fowler smell baseline — see [references/smells.md](references/smells.md)
- Any project-specific linting not covered by tooling

**Spec axis (find the originating requirement):**
- Commit messages for issue references (`#123`, `Closes #45`)
- `.memory/specs/` — feature specs matching the branch/feature name
- `.memory/grill/` — grill session findings related to this work
- If no spec found: note "no spec available" and skip this axis

### 3. Dispatch review subagent(s)

Provide the subagent with:
- The diff (or file list + contents)
- The relevant axis sources (standards OR spec — not both to the same subagent)
- Do NOT provide: task description, design rationale, or conversation history

**Standards subagent:** Reviews against coding standards + smell baseline.
**Spec subagent:** Reviews against the spec — does it implement what was specified? Missing anything? Scope creep?

If spec is unavailable, run standards-only.

### 4. Report findings

Merge findings from both axes. Group by severity, cap at 5 critical/important items.

## Review Checklist (for subagent)

**Priority order:**

1. **Correctness** — Does it work? Edge cases? Error paths explicit?
2. **Security** — Hardcoded secrets? Input validation? Injection vectors?
3. **Design** — Single responsibility? Focused functions? No implicit coupling?
4. **Testing** — New code has tests? Covers happy path + at least one error path?

## Feedback Format

```
[SEVERITY] file:line — Issue summary.
  Request: What to change.
  Reason: Why it matters.
```

**Severities:**
- **CRITICAL**: Must fix. Security, data loss, broken functionality.
- **IMPORTANT**: Should fix. Bug, missing error handling.
- **NIT**: Nice to fix. Style, naming. Don't block on these.

## Signals to Flag

| Signal | Issue |
|--------|-------|
| Function > 20 lines or needs "and" to describe | Too broad |
| Empty catch blocks | Silent error swallowing |
| Signature doesn't match behavior | Functions that lie |
| Module reaches into another's internals | Implicit coupling |

## Rules

- Reviewer verifies claims against actual code (reads the file, not just the diff)
- Never say "looks good" without checking
- Cap at 5 findings; defer low-severity with a count
- If the review is clean, say so in one line — don't manufacture feedback

## Verdict System

Every review MUST end with exactly one verdict line. No exceptions.

| Verdict | Meaning | Action |
|---------|---------|--------|
| **APPROVED** | No critical/important issues | Merge |
| **CHANGES REQUESTED** | Issues found, specific fixes listed | Author fixes, re-review |
| **NEEDS DISCUSSION** | Design-level concern, not a code fix | Escalate to planning |

Output format: `**Verdict: APPROVED**` or `**Verdict: CHANGES REQUESTED**` or `**Verdict: NEEDS DISCUSSION**`

**Max 2 review rounds.** If still not approved after 2 rounds, escalate — the disagreement is architectural, not code-level.
