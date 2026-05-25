---
name: cheatsheet
description: "Quick reference for all available prompts and their usage. Use when you need a reminder of what's available."
metadata:
  type: reference
  invocation: user-only
  practice: null
---

# Prompt Cheatsheet

## Session Lifecycle

| Prompt | When to Use |
|--------|-------------|
| `@read-handoff` | **Start of session.** Reads the handoff, orients you, reports what's done and what's next. |
| `@handoff` | **End of session.** Writes a handoff so the next session can continue without re-discovery. |

## Project Setup

| Prompt | When to Use |
|--------|-------------|
| `@init-project` | **New project.** Scaffolds .scratch, .memory, CONTEXT.md, AGENTS.md, .crew-config.yaml, and generates the full agent deployment. Auto-detects language and verification commands. |

## Design & Planning

| Prompt | When to Use |
|--------|-------------|
| `@ux-walkthrough` | **Designing an interface.** Walks through a user flow step-by-step asking: what will they see, think, do, and what happens? Surfaces usability issues before building. |

## Maintenance

| Prompt | When to Use |
|--------|-------------|
| `@workspace-cleanup` | **Periodic housekeeping.** Promotes scratch→memory, deduplicates memory, organizes scripts, updates task runner, verifies steering/skills accuracy, checks README/AGENTS.md currency. |
| `@cheatsheet` | **This prompt.** Quick reference for what's available. |

## Agents (invoke with --agent)

| Agent | Role |
|-------|------|
| `lead` | Orchestrates workers. Delegates, verifies, reports. Entry point for complex tasks. |
| `implementer` | Writes code. Reads existing patterns, implements, verifies with tests. |
| `researcher` | Investigates. Gathers evidence, cites sources, writes structured findings. |
| `reviewer` | Evaluates. Read-only code review with severity-ranked findings. |
| `planner` | Decomposes. Breaks work into sequenced tasks with acceptance criteria. |
| `writer` | Produces docs. Structured, accurate, concise written artifacts. |
| `tester` | Validates. Writes and runs tests, reports pass/fail with evidence. |
| `operator` | Infra ops. Provisions, deploys, monitors, handles rollback. |
| `dispatcher` | Routes. Sends requests to the right crew lead automatically. |

## Tips

- Start sessions with `@read-handoff`, end with `@handoff`
- For complex work: `kiro-cli chat --agent lead "your task"`
- For quick tasks: just ask directly (no agent needed)
- Run `@workspace-cleanup` weekly or when things feel cluttered
