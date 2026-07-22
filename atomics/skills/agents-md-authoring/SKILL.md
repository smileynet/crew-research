---
name: agents-md-authoring
description: "Write concise, effective AGENTS.md files for projects. Use when creating, rewriting, or trimming an AGENTS.md. Trigger: AGENTS.md, agent guidance, project instructions, agent-facing docs, too long, bloated."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# AGENTS.md Authoring

Write agent-facing project guidance that's short enough to stay in attention and structured enough to be actionable.

## Why ≤150 Lines

Beyond 150 lines, agents spend reasoning tokens parsing instructions instead of working. Every line competes with the actual task for attention. The agent that reads a 300-line AGENTS.md produces worse output than one reading 100 lines — the guidance drowns the work.

## Required Sections

| Section | Purpose | Max lines |
|---------|---------|-----------|
| Project | What this is (1-2 sentences) | 3 |
| Workspace Layout | Where things live | 10-15 |
| Commands | How to build/test/lint/deploy | 10-15 |
| Workflow | Decision tables, routing | 10-20 |
| Constraints | Don'ts paired with dos | 10-15 |
| When Blocked | Escalation rules | 5-10 |

## Process

1. **Inventory** — read the project's README, build config, test setup, CI
2. **Extract** — identify commands, conventions, constraints, file layout
3. **Compress** — write each section at target line count
4. **Link out** — anything that needs more than 3 lines of explanation → link to `docs/` or `.memory/`
5. **Verify** — count lines, check gates

## Writing Rules

- **Commands must be verifiable** — include expected output or exit code ("runs 47 tests, exits 0")
- **Pair don'ts with dos** — not just "don't do X" but "do Y instead"
- **Decision tables over prose** — "if X then Y" beats paragraphs
- **Gate criteria use the source methodology's native tests, not proxies** — when a rule routes work to a methodology or tool, derive its trigger from that system's own decision concepts (e.g., "do two forces conflict?" from the design method itself), not from size or category proxies ("new subsystem", "big change"). Proxies over- and under-fire; native tests teach the underlying lens while gating
- **Progressive disclosure** — AGENTS.md is the index; detail lives in linked files
- **Agent audience only** — no user onboarding, no contribution guidelines, no marketing

## Gates (mandatory before presenting)

| # | Gate | Fail action |
|---|------|-------------|
| G1 | Total ≤150 lines | Extract detail to linked docs |
| G2 | Commands section has verifiable done criteria | Add expected output/exit code |
| G3 | "When Blocked" section exists with escalation rules | Add it |
| G4 | Every "don't" has a corresponding "do instead" | Pair them |
| G5 | No prose paragraphs >3 lines (use tables/lists) | Restructure |

If G1-G5 don't all pass, fix before presenting.

## When Trimming an Existing AGENTS.md

1. Count lines. If >150, identify sections that explain rather than instruct.
2. Extract explanations → `docs/` files, replace with link. **Extraction means writing the file**: create the target doc with the removed content, then link it. A link to a file that doesn't exist — or content that simply vanishes — is deletion, not extraction. Preserve named pitfalls and project-specific rules somewhere reachable.
3. Convert prose constraints to table rows.
4. Remove anything the agent can discover from the codebase (don't document what `package.json` already says).
5. Re-count. Still over? Cut the least-actionable content.

## Anti-Patterns

| Problem | Fix |
|---------|-----|
| README content duplicated | Delete — agent can read README itself |
| "Please" and "try to" | Direct imperatives: "Do X" |
| Architecture explanations | Link to docs/architecture.md |
| Lists of every file | Just show the layout tree |
| Generic advice ("write clean code") | Remove — adds nothing |
