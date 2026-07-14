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
- **Inline in the user's prompt** — if the user says "The spec says: ..." use that directly
- Commit messages for issue references (`#123`, `Closes #45`)
- `.memory/specs/` — feature specs matching the branch/feature name
- `.memory/grill/` — grill session findings related to this work
- If no spec found anywhere: note "no spec available" and skip this axis

### 3. Dispatch review subagent(s)

Provide the subagent with:
- The diff (or file list + contents)
- The relevant axis sources (standards OR spec — not both to the same subagent)
- Do NOT provide: task description, design rationale, or conversation history

**Standards subagent:** Reviews against coding standards + smell baseline.
**Spec subagent:** Reviews against the spec — does it implement what was specified? Missing anything? Scope creep?

If spec is unavailable, run standards-only.

### 4. Report findings — axes separate

Present each axis as its own section. Do NOT merge findings across axes.

```
## Standards
[findings from standards review, grouped by severity]

## Spec
[findings from spec review — missing requirements, scope creep, misimplementation]
```

**If no spec was found:** replace the Spec section with:
```
## Spec: N/A
No originating spec found (checked: prompt, commit messages, .memory/specs/, .memory/grill/).
Review is standards-only.
```

This separation prevents one axis from masking the other. A change can pass Standards but miss the Spec, or implement the Spec perfectly while violating conventions.

Cap at 5 findings per axis. End with a verdict that considers both.

For the subagent review checklist and signal patterns, see [references/checklist.md](references/checklist.md).

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
