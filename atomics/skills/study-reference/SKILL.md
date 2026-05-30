---
name: study-reference
description: "Deep-dive a tool or repo in resources/. Documents purpose, usage, novel patterns, and distills learnings into steering/skills. Use when onboarding a new reference repo or tool."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Study Reference

Analyze a tool or third-party repo and extract actionable knowledge from it.

## Phase 1: Document

Dispatch a subagent to explore the repo/tool and write a reference doc to `.memory/`:

**Output: `.memory/{name}-reference.md`**
- **Purpose** — what it does, what problem it solves
- **Usage** — how to invoke/use it (commands, API, key patterns)
- **Architecture** — how it's structured (key files, entry points, data flow)
- **Novel Patterns** — techniques worth adopting (things we haven't seen before)
- **Anti-patterns** — things it does that we should avoid or do differently
- **Integration Points** — how it connects to our project

## Phase 2: Distill

Review the reference doc and identify what should become project guidance:

- **Steering candidates** — behavioral rules that apply every turn
  (e.g., "always use X pattern when doing Y" → `.kiro/steering/`)
- **Skill candidates** — on-demand knowledge for specific tasks
  (e.g., "when working with this tool, follow these steps" → `.kiro/skills/`)
- **CONTEXT.md terms** — vocabulary introduced by this tool/repo
- **AGENTS.md updates** — new commands, tool references

Present candidates and wait for approval before applying.

## Phase 3: Apply

For each approved candidate:
1. Write the steering file or skill
2. Update CONTEXT.md with new terms
3. Update AGENTS.md if commands/tools changed
4. Commit with: `docs: study {name} — {what was learned}`

## Rules

- One reference doc per tool/repo (don't split across files)
- Novel patterns section is the highest-value output — be specific about WHAT is novel and WHY
- Only create steering for patterns that apply every turn
- Only create skills for knowledge needed during specific tasks
- If the repo is large, focus on the parts relevant to our project
