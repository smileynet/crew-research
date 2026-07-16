---
name: study-all-references
description: "Batch study all repos/tools in .references/. Dispatches parallel subagents to document each, then distills learnings into steering/skills. Use when onboarding to a project with multiple reference repos."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Study All References

Analyze every repo/tool in `.references/` and extract actionable knowledge.

## Step 1: Inventory

List all directories in `.references/`. For each, note what it appears to be (language, purpose, size).

## Step 2: Document (parallel)

For each reference, check if `.memory/{name}-reference.md` already exists with `studied_at` frontmatter. Skip those — already studied. Only dispatch subagents for unstudied references.

Dispatch one subagent per unstudied reference. **Each doc follows the study-reference skill's schema** — same frontmatter (`studied_at`, `source: .references/{name}`), same seven analysis dimensions (JTBD, Decisions and tradeoffs, Non-obvious, Prior art, Audience, Conventions, Integration points). This skill is the batch driver; study-reference owns the document structure.

Subagent prompt template:
```
Explore .references/{name}/ thoroughly. Read key files (README, main entry points, config).
Write a reference doc to .memory/{name}-reference.md following the structure in
.kiro/skills/study-reference/references/exploration-template.md (JTBD, Decisions and
tradeoffs, Non-obvious, Prior art, Audience, Conventions, Integration points), with
frontmatter: studied_at ({ISO 8601 timestamp}) and source (.references/{name}).
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
