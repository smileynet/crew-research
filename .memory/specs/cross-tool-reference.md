---
type: specification
title: "Cross-Tool Context Delivery Reference"
---

# Cross-Tool Context Delivery Reference

## Context Delivery Mechanisms by Tool

| Mechanism | kiro-cli | Claude Code | Codex | Pi |
|-----------|----------|-------------|-------|-----|
| Eager (always-on) | `.kiro/steering/**/*.md` | `CLAUDE.md` (hierarchical) | `AGENTS.md` | `AGENTS.md` |
| Lazy (on-demand) | `skill://` in agent resources | `.claude/skills/*/SKILL.md` | `~/.codex/skills/**/SKILL.md` | `~/.pi/agent/skills/**/SKILL.md` |
| Per-agent binding | `resources` field in agent JSON | Subagent `skills` field (preloaded) | Unknown | Unknown |
| Agent format | JSON | Markdown + YAML frontmatter | Unknown | Unknown |
| Non-interactive | `--no-interactive -a` | `--print` | Unknown | Unknown |

## Key Architectural Differences

**kiro-cli**: Binds context to agents explicitly — each agent declares what files/skills it can access via `resources`.

**Claude Code**: Project-wide discovery — all skills in `.claude/skills/` are available to all agents. Scoping via subagent `skills` field (preloads full content at spawn).

**CLAUDE.md is project-wide** — all agents see it. Per-agent eager context must go in subagent system prompt body.

## Claude Code Subagent Loading Order

1. System prompt (markdown body of agent definition)
2. Task message (delegation prompt from parent)
3. CLAUDE.md + memory hierarchy
4. Git status snapshot
5. Preloaded skills (full content of `skills` field entries)

Constraints: subagents cannot spawn other subagents; start with fresh context.

## Frontmatter Compatibility

| Field | kiro-cli | Claude Code | Codex | Pi |
|-------|----------|-------------|-------|-----|
| `name` | ✅ | ✅ | ✅ | ✅ |
| `description` | ✅ | ✅ | ✅ | ✅ |
| Custom fields (`type`, `practice`) | Ignored | Stripped (harmless) | Likely ignored | Likely ignored |
| `disable-model-invocation` | ❓ | ✅ Native | ❓ | ❓ |

## Generator Invocation Mapping

| Source (`metadata.invocation`) | kiro-cli | Claude Code |
|-------------------------------|----------|-------------|
| `user-only` | Emit to `.kiro/prompts/` | Add `disable-model-invocation: true` |
| `agent-only` | Normal skill | Add `user-invocable: false` |
| `both` (default) | Normal skill | No extra fields |

## Proof Harness Implications

- kiro-cli: deploy file → add `file://` to agent's resources
- Claude Code: deploy as CLAUDE.md (eager) or skill with matching description (lazy)
- Abstract fixture types: `eager_file`, `skill`, `agent` — adapter maps to tool-specific delivery
