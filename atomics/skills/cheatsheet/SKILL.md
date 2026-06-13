---
name: cheatsheet
description: "Quick reference for all available skills and workflows. Use when you need a reminder of what's available."
metadata:
  type: reference
  invocation: user-only
  practice: null
---

# Cheatsheet

## Workflows

| Command | When to use |
|---------|-------------|
| `/read-handoff` | **Start of session.** Reads the handoff, orients you, reports what's done and what's next. |
| `/handoff` | **End of session.** Writes a handoff so the next session can continue without re-discovery. |
| `/grill-with-docs` | **Designing something.** Interrogates your plan one question at a time, updates CONTEXT.md inline. |
| `/plan-prereqs` | **Before building.** Identifies research, spikes, and tooling needed before implementation. |
| `/project-cleanup` | **Periodic housekeeping.** Promotes scratch→memory, deduplicates, processes decisions→ADR, verifies accuracy. |
| `/project-audit` | **Drift check.** Verifies commands work, AGENTS.md is accurate, skills are relevant. |
| `/adopt-project` | **Brownfield migration.** Inventories existing setup, captures special instructions, deploys. |

## Workflow

```
Start session → /read-handoff
Plan work → describe what you want (planning-cycles activates)
Stress-test → /grill-with-docs
Pre-work → /plan-prereqs
Build → just work (steering enforces hygiene + verification)
End session → /handoff
Weekly → /project-cleanup
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

## Project-Level Skills (install per-project)

These are NOT in global tiers. Install to a project's `.kiro/skills/` when needed:

```bash
mise run add-skill -- <name>
```

| Skill | Install when project involves... |
|-------|----------------------------------|
| `fiction-craft` | Stories, game narrative, creative prose |
| `world-building` | Fictional worlds, magic systems, game rules |
| `presentation-writing` | Slide decks, MARP, demo scripts, workshops |
| `poc-workflow` | Proofs of concept, "prove this works" |
| `prototype-protocol` | Throwaway prototypes, "let me play with it" |
| `ux-walkthrough` | Interface design, user flow evaluation |
| `tutorial-authoring` | Getting-started guides, onboarding docs |
| `eval-criteria` | Scoring rubrics, LLM-judged evals |
| `skill-authoring` | Writing or improving agent skills |
| `session-review-patterns` | Reviewing session transcripts for quality |
| `enforcement-hierarchy` | Deciding how to enforce agent behavior rules |
| `project-conventions` | Project-specific behavioral rules |

**When to suggest:** during init, adopt-project, read-handoff, or when a plan includes matching work.
