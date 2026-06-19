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

Dispatch a subagent for the review. Subagents have clean context — no knowledge of why the code was written — which produces more neutral, thorough reviews.

### 1. Gather the diff

```bash
git diff main          # or git diff HEAD~1, or the relevant range
```

### 2. Dispatch review subagent

Provide the subagent with:
- The diff (or file list + contents)
- The review checklist below
- Any project-specific rules from `.kiro/steering/`

Do NOT provide: the task description, design rationale, or conversation history. The reviewer should evaluate the code on its own merits.

### 3. Report findings

Summarize the subagent's findings. Group by severity, cap at 5 critical/important items.

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
