---
name: study-all-references
description: "Batch study all repos/tools in resources/. Dispatches parallel subagents to document each, then distills learnings into steering/skills. Use when onboarding to a project with multiple reference repos."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Study All References

Analyze every repo/tool in `resources/` and extract actionable knowledge.

## Step 1: Inventory

List all directories in `resources/`. For each, note what it appears to be (language, purpose, size).

## Step 2: Document (parallel)

Dispatch one subagent per reference repo. Each writes to `.memory/{name}-reference.md`:

- **Purpose** — what it does, what problem it solves
- **Usage** — how to invoke/use it (commands, API, key patterns)
- **Architecture** — key files, entry points, data flow
- **Novel Patterns** — techniques worth adopting
- **Anti-patterns** — things to avoid
- **Integration Points** — how it connects to our project

Subagent prompt template:
```
Explore resources/{name}/ thoroughly. Read key files (README, main entry points, config).
Write a reference doc to .memory/{name}-reference.md with sections:
Purpose, Usage, Architecture, Novel Patterns, Anti-patterns, Integration Points.
Focus on what's relevant to THIS project (read AGENTS.md for context).
```

## Step 3: Synthesize

After all subagents complete, read all `.memory/*-reference.md` files and produce:

### Cross-cutting patterns
Patterns that appear in multiple references (consensus = high confidence).

### Steering candidates
Rules that should apply every turn. For each:
- What rule
- Which references support it
- Proposed steering file name

### Skill candidates
On-demand knowledge for specific tasks. For each:
- What knowledge
- When it's needed (activation trigger)
- Which references inform it

### CONTEXT.md terms
New vocabulary from the references.

## Step 4: Apply (with approval)

Present all candidates. After user approves:
1. Write steering files to `.kiro/steering/`
2. Write skills to `.kiro/skills/`
3. Update `.memory/CONTEXT.md`
4. Update `AGENTS.md` with new tool references
5. Commit: `docs: study all references — {summary of learnings}`

## Rules

- Max 4 subagents per batch (kiro-cli limit). If >4 references, batch in groups.
- Skip references that already have a `.memory/{name}-reference.md` (already studied).
- Cross-cutting patterns (found in 2+ repos) are higher confidence than single-source findings.
- Present candidates grouped by confidence before applying.
