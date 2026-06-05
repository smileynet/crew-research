---
name: cheatsheet
description: "Quick reference for all available skills and workflows. Use when you need a reminder of what's available."
metadata:
  type: reference
  invocation: user-only
  practice: null
---

# Cheatsheet

## Prompts

| Prompt | When to use |
|--------|-------------|
| `@read-handoff` | **Start of session.** Reads the handoff, orients you, reports what's done and what's next. |
| `@handoff` | **End of session.** Writes a handoff so the next session can continue without re-discovery. |
| `@grill-with-docs` | **Designing something.** Interrogates your plan one question at a time, updates CONTEXT.md inline. |
| `@plan-prereqs` | **Before building.** Identifies research, spikes, and tooling needed before implementation. |
| `@project-cleanup` | **Periodic housekeeping.** Promotes scratch→memory, deduplicates, processes decisions→ADR, verifies accuracy. |
| `@project-audit` | **Drift check.** Verifies commands work, AGENTS.md is accurate, skills are relevant. |
| `@adopt-project` | **Brownfield migration.** Inventories existing setup, captures special instructions, deploys. |
| `@research-prior-art` | **Need evidence.** Researches reference repos to inform a design decision. |

## Workflow

```
Start session → @read-handoff
Plan work → describe what you want (planning-cycles activates)
Stress-test → @grill-with-docs
Pre-work → @plan-prereqs
Build → just work (steering enforces hygiene + verification)
End session → @handoff
Weekly → @project-cleanup
```

## Key Skills (activate automatically)

| Skill | Triggers on |
|-------|-------------|
| planning-cycles | "plan this", "break this down", starting a feature |
| five-whys | "why is this happening", "root cause", debugging |
| troubleshooting-protocol | errors, failures, "help me debug" |
| code-review | "review this", "check for issues" |
| testing-guide | "write tests", "what should I test" |
| git-protocol | "commit", "push", "branch" |
