---
type: specification
title: "Eager-Context Format Specification"
status: active
---

# Eager-Context Format Specification

## Overview

Eager-context modules are always-loaded project context injected at session start and present every turn. They are the portable equivalent of kiro-cli steering, Claude Code CLAUDE.md, and Codex/Pi AGENTS.md.

## Directory Structure

```
atomics/eager-context/{slug}.md
```

Eager-context modules are single markdown files (no directory needed — they're short by design).

## Format

```yaml
---
name: {slug}
scope: universal | orchestrator | worker
description: What this context provides and why it's always-loaded.
---

[Content: concise behavioral constraints, conventions, or workspace contracts]
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Matches filename (without `.md`). Lowercase, hyphens. |
| `scope` | Yes | Which agents receive this: `universal` (all), `orchestrator` (leads), `worker` (executors) |
| `description` | Yes | Brief explanation of what this provides. |

## Content Guidelines

- Keep under 50 lines. Every line is paid every turn.
- State constraints, not explanations. "Verify before claiming done" not "It's important to verify because..."
- Use imperative voice. These are standing orders, not suggestions.
- If content is situational, it belongs in a skill, not eager-context.

## Authoring Heuristic

Put content in eager-context if ALL of these are true:
1. Applies regardless of task (not situational)
2. Agent must follow this every turn (not just when triggered)
3. Under 50 lines (not reference material)

If any are false → use a skill instead.

## Examples

**Workspace contract:**
```yaml
---
name: workspace
scope: universal
description: Defines ephemeral and durable workspace roots for agent coordination.
---

| Root | Path | Lifecycle |
|------|------|-----------|
| Ephemeral | .scratch/ | ≤ one handoff cycle |
| Durable | .memory/ | Persists across sessions |

- Handoff lives at .scratch/HANDOFF.md
- All shared artifacts require frontmatter: created_at, base_commit
- Never link ephemeral content from durable docs
```

**Verification constraint:**
```yaml
---
name: verification
scope: worker
description: Mandatory verification gate before claiming completion.
---

Before reporting DONE: identify checks → run them → read output → verify correctness → claim.
Never claim completion without fresh evidence.
```

## Generator Delivery

| Tool | Delivery | Notes |
|------|----------|-------|
| kiro-cli | `.kiro/steering/{scope}/{name}.md` | Adds `inclusion: always` frontmatter |
| Claude Code | Merged into `CLAUDE.md` | Hierarchical: root for universal, subdirectory for scoped |
| Pi | Merged into `AGENTS.md` | Single file, sections per scope |
| Codex | Merged into `AGENTS.md` | Single file |

## Scope Mapping

| Scope | Who receives | Use for |
|-------|-------------|---------|
| `universal` | All agents | Workspace contract, signaling format, sanity gate |
| `orchestrator` | Leads/dispatchers | Delegation rules, narration protocol, routing tables |
| `worker` | Executors | Verification gate, git protocol, troubleshooting escalation |

## Hierarchical Eager Loading (Claude Code specific)

Claude Code supports per-directory CLAUDE.md files loaded bottom-up. The generator can emit scoped eager-context as nested CLAUDE.md files for projects that benefit from localized context. This is a delivery optimization, not a source format concern.
