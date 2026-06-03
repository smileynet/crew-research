---
name: study-reference
description: "Deep-dive a tool or repo in references/. Documents purpose, usage, novel patterns, and distills learnings into steering/skills. Use when onboarding a new reference repo or tool."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Study Reference

Analyze a tool or third-party repo and extract actionable knowledge from it.

## Phase 1: Document

Check if `.memory/{name}-reference.md` already exists with a `studied_at` frontmatter field. If it does, skip — already studied. If the file exists but has no frontmatter (legacy/partial), re-study.

Dispatch a subagent to explore the repo/tool and write a reference doc to `.memory/`:

**Output: `.memory/{name}-reference.md`**
```markdown
---
studied_at: {ISO 8601 timestamp}
source: references/{name}
---
```

Analyze along these dimensions:

1. **JTBD** — what user problems does this solve? (situations, not features)
2. **Decisions and tradeoffs** — what was chosen, what was traded off, why?
3. **Non-obvious** — gotchas, edge cases, hidden complexity, failure modes, subtle interactions
4. **Prior art** — what known patterns does this implement or deviate from?
5. **Audience** — who uses this, what do they need to know, at what abstraction level?
6. **Conventions** — local rules, naming, deviations from standard practice
7. **Integration points** — how it connects to our project

## Phase 2: Distill

Review the reference doc and identify what should become project guidance:

- **Steering candidates** — behavioral rules that apply every turn
- **Skill candidates** — on-demand knowledge for specific tasks
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
- Non-obvious section is the highest-value output — be specific about failure modes and gotchas
- Only create steering for patterns that apply every turn
- Only create skills for knowledge needed during specific tasks
- If the repo is large, focus on the parts relevant to our project
