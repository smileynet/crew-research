---
name: commit-pr-discipline
description: >
  Commit message and pull request discipline. Use when writing commit
  messages, creating PRs, staging changes, or deciding how to group work.
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Commit and PR Discipline

## Commit Subject Line
1. State **what changed** (not how, not why)
2. Imperative mood: "add", not "added"
3. Lowercase, no trailing period
4. 50 chars target, 72 max

## Commit Body
- 1–3 sentences: what a developer would notice, and why
- Impact, not mechanism (the diff shows mechanism)
- Wrap at 72 chars

## Pre-Commit Checks
```
git log --oneline -20       # extending recent work?
git diff --stat             # unintended files? unstage them
```

## Grouping Rules

**Group together:**
- Production fix + its test
- Rename propagated across files

**Separate:**
- Bug found while building a feature → own commit
- Unrelated cleanup → own commit

**Scope test:** if the subject needs "and" to connect unrelated things, split.

## PR Title Format
```
type(scope): description
```
Types: feat, fix, refactor, chore, docs, test, ci, perf

## PR Body Structure
1. **What** — one sentence summary
2. **Why** — context/motivation
3. **How to test** — verification steps
4. **Scope** — what's NOT included

## Size Targets
- Ideal: <300 lines changed
- Max: 500 lines (split if larger)
- One logical change per PR

## Anti-Patterns
| Pattern | Problem |
|---------|---------|
| Subject-only, no body | Forces reader into diff |
| "updates", "fixes", "wip" | Unreadable log |
| Kitchen-sink commits | Multiple unrelated changes |
| Micro-commits ("add import") | Don't build/pass alone |
