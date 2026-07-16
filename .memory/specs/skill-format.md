---
type: specification
title: "Skill Format Specification"
status: active
---

# Skill Format Specification

## Overview

Skills are the universal delivery mechanism for on-demand agent knowledge. A skill is a directory containing a `SKILL.md` entry point with YAML frontmatter and optional supporting files loaded progressively.

## Directory Structure

```
atomics/skills/{slug}/
├── SKILL.md              # Required: frontmatter + instructions (<100 lines)
├── references/           # Optional: detailed docs loaded on-demand
│   ├── examples.md
│   └── troubleshooting.md
├── scripts/              # Optional: helper scripts
└── templates/            # Optional: output templates
```

## SKILL.md Format

```yaml
---
name: {slug}
description: >
  What this skill does (first sentence). Use when [specific triggers]
  (second sentence with keywords that match activation contexts).
metadata:
  type: protocol | reasoning-mode | reference | decision | process
  invocation: both | user-only | agent-only
  practice: {slug}          # optional: source practice that produced this skill
  params:                   # optional: project-customizable values with defaults
    build_command: "npm run build"
---

# Skill Title

[Instructions: what the agent should DO when this skill is active]
```

## Frontmatter Fields

### Standard (top-level, spec-compliant)

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase a-z, 0-9, hyphens. Must match directory name. Max 64 chars. |
| `description` | Yes | Max 1024 chars. First sentence = what it does. Second = trigger phrases. |
| `metadata` | No | Arbitrary key-value map for our custom fields. Preserved in deployed files. |

### Custom (inside `metadata`, consumed by our tooling)

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Content type: `protocol`, `reasoning-mode`, `reference`, `decision`, `process` |
| `invocation` | No | Who can trigger: `both` (default), `user-only`, `agent-only` |
| `practice` | No | Slug of the source practice in `docs/practices/` |
| `params` | No | Project-customizable values with defaults (see ADR 0002) |

## Content Guidelines

- SKILL.md body stays under 100 lines
- Focus on what to DO, not background knowledge (that goes in `references/`)
- Use progressive loading: link to supporting files with "when to read" context
- Include trigger phrases in description that match real user language
- Anti-patterns and troubleshooting go in `references/troubleshooting.md`

## Type Templates

### Protocol (`type: protocol`)
Numbered steps with gate conditions. Naming convention: `{name}-protocol`.
```markdown
## Steps
1. Step one — gate: [condition to proceed]
2. Step two — gate: [condition to proceed]
...

## Constraints
- NEVER [prohibited action]
- ALWAYS [required action]
```

### Reasoning Mode (`type: reasoning-mode`)
Thinking pattern activation. Named by keyword.
```markdown
## When to Use
[Specific situations that call for this thinking pattern]

## Process
[How to apply this reasoning mode]

## Output Shape
[What the result looks like]
```

### Reference (`type: reference`)
Lookup tables, patterns, common mistakes.
```markdown
## Patterns
| Signal | Action |
|--------|--------|
...

## Common Mistakes
...
```

### Decision (`type: decision`)
Selection criteria, when-to-switch signals.
```markdown
## Selection Criteria
| Situation | Choose |
|-----------|--------|
...

## When to Switch
[Signals that the current approach isn't working]
```

### Process (`type: process`)
Numbered workflow steps (not gated like protocols).
```markdown
## Workflow
1. [Step]
2. [Step]
...
```

## Progressive Loading

Reference supporting files from SKILL.md with explicit "when to read" context:

```markdown
For TypeScript-specific examples, see [references/examples-typescript.md](references/examples-typescript.md).
If the approach isn't working, see [references/troubleshooting.md](references/troubleshooting.md).
```

## Generator Delivery

The generator reads `metadata.invocation` and emits tool-native fields during deployment:

| Tool | Location | `invocation: user-only` | `invocation: agent-only` |
|------|----------|------------------------|-------------------------|
| kiro-cli | `.kiro/skills/{name}/SKILL.md` | Emits to `.kiro/prompts/{name}.md` instead | Default (no change) |
| Claude Code | `.claude/skills/{name}/SKILL.md` | Adds `disable-model-invocation: true` | Adds `user-invocable: false` |
| Pi | `~/.pi/agent/skills/{name}/SKILL.md` | Emits as prompt template | Default (no change) |
| Codex | `~/.codex/skills/{name}/SKILL.md` | Standard delivery | Standard delivery |

The `metadata` block is preserved in deployed files (spec-compliant, tools ignore it). Tool-native fields are ADDED by the generator — they don't exist in source.

## Validation Rules

- Directory name matches `name` field in frontmatter
- `description` is non-empty and under 1024 chars
- SKILL.md body is under 100 lines (warn) or 500 lines (error)
- `metadata.type` is one of the allowed values (if present)
- `metadata.practice` reference resolves to an existing file (if present)
- `metadata.invocation` is one of: `both`, `user-only`, `agent-only` (if present)
- Only standard fields at top level (`name`, `description`, `metadata`, `license`, `compatibility`)
