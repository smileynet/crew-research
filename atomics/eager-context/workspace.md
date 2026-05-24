---
name: workspace
scope: universal
description: Defines ephemeral and durable workspace roots for agent coordination.
---

# Workspace

| Root | Path | Lifecycle | Use for |
|------|------|-----------|---------|
| Ephemeral | `.scratch/` | ≤ one handoff cycle | Handoff, scratch notes, drafts |
| Durable | `.memory/` | Persists across sessions | Decisions, glossary, references |

## Rules

- Handoff lives at `.scratch/HANDOFF.md`
- All shared artifacts require YAML frontmatter: `created_at`, `base_commit`
- Never link ephemeral content from durable docs
- Treat ephemeral as expendable — newer handoff supersedes older
