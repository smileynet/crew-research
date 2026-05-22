---
created_at: 2026-05-21T20:32:00-07:00
base_commit: 83b17a2
---

# Spike S6 & S7 Results

## S6: Cross-Tool Proof Abstraction

**Decision: Option A — Abstract fixture types.**

Proof definitions use abstract context types (`eager_file`, `skill`, `agent`). The adapter maps them to tool-specific mechanisms.

| Abstract Type | kiro-cli | Claude Code |
|---------------|----------|-------------|
| `eager_file` | `file://` in agent resources | Content in CLAUDE.md |
| `skill` | `skill://` in agent resources + SKILL.md | `.claude/skills/` directory |
| `agent` | JSON in `.kiro/agents/` | Markdown in `.claude/agents/` |

Harness reads adapter to determine delivery. One proof definition works across tools.

## S7: Per-Agent Skill Scoping in Claude Code

**Answer: Solved via subagent `skills` field.**

From official docs: the `skills` frontmatter field on subagents preloads full skill content at startup. Combined with `disallowedTools: Skill`, this gives strict per-agent scoping.

Generator mapping:
- Archetype `skills: [list]` → subagent `skills: [list]` (preloaded)
- Archetype `tools: [list]` → subagent `tools: [list]`
- Archetype `eager-context: [list]` → content in subagent system prompt body (not CLAUDE.md, since that's project-wide)

**Limitation:** CLAUDE.md is project-wide (all agents see it). Scoped eager-context (orchestrator-only, worker-only) must go in the subagent's system prompt body instead.
