---
name: code-review
description: "Code review standards and checklist. Use when reviewing code, PRs, or implementations for correctness, security, and quality."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Code Review Standards

## Review Priority (check in this order)

### 1. Correctness
- Does it do what it's supposed to?
- Edge cases handled? (null, empty, boundary)
- Error paths explicit? (no silent swallowing)

### 2. Security
- No hardcoded secrets
- Input validation on external inputs
- Least-privilege permissions
- No injection vectors (SQL, XSS, command)

### 3. Design
- Single responsibility per function/class
- Small and focused (describe without "and")
- No implicit coupling between modules

### 4. Testing
- New code has tests (behavior, not implementation)
- Happy path + at least one error path

## Feedback Format

Every comment: **Request, Reason, Result**:
```
[SEVERITY] file:line — Issue summary.
  Request: What to change.
  Reason: Why it matters.
```

## Severity
- **CRITICAL**: Must fix. Security, data loss, broken functionality.
- **IMPORTANT**: Should fix. Bug, missing error handling.
- **NIT**: Nice to fix. Style, naming. Don't block on these.

## Antipatterns to Flag
| Signal | Issue |
|--------|-------|
| Function > 20 lines or needs "and" to describe | God method |
| Empty catch blocks | Silent error swallowing |
| Signature doesn't match behavior | Functions that lie |
| Module reaches into another's internals | Implicit coupling |

## Rules
- Verify claims against actual code (read the file)
- Never say "looks good" without checking
- Cap at 5 findings; defer low-severity with a count
