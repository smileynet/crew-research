# Generator Specification (Optional Build Layer)

## Overview

The generator is an optional tool that composes atomic modules and compositions into tool-specific deployments. Modules work standalone without the generator; the generator adds consistency enforcement and multi-tool output.

## Role

- Reads compositions (agent archetypes, crew patterns, workspace conventions)
- Resolves references to atomic modules (skills, eager-context)
- Emits tool-specific output using adapter profiles
- Validates cross-references and enforces constraints

## Input

```
atomics/skills/         → skill modules
atomics/eager-context/  → always-loaded context
compositions/           → YAML manifests
tools/proofs/adapters/  → tool profiles (for delivery format)
```

## Output (per tool, per project)

```
.kiro/                  → kiro-cli deployment
  agents/*.json
  skills/*/SKILL.md
  steering/**/*.md
  prompts/*.md

.claude/                → Claude Code deployment
  agents/*.md
  skills/*/SKILL.md
  CLAUDE.md (merged eager-context)

AGENTS.md               → Codex/Pi deployment (merged eager-context)
```

## Operations

### 1. Resolve References
- For each composition, resolve all skill/eager-context/archetype references to actual files
- Report unresolved references as errors

### 2. Map Invocation Control
- Skills with `invocation: user-only` → kiro-cli prompts, Claude Code `disable-model-invocation: true`
- Skills with `invocation: agent-only` → Claude Code `user-invocable: false`
- Skills with `invocation: both` → default delivery

### 3. Scope Eager-Context
- `scope: universal` → delivered to all agents
- `scope: orchestrator` → delivered only to lead agents
- `scope: worker` → delivered only to worker agents

### 4. Emit Agent Configs
- Read agent archetype YAML
- Merge: archetype prompt + skill references + eager-context + tools
- Emit in tool-specific format (JSON for kiro-cli, markdown for Claude Code)

### 5. Validate
- All references resolve
- No circular dependencies
- Skills under line limits
- Cross-links intact (practice ↔ skill)

## CLI Interface

```bash
# Generate for a specific tool
crew-research generate --tool kiro-cli --output ./deploy/

# Generate for all tools
crew-research generate --all --output ./deploy/

# Validate without generating
crew-research validate

# Check cross-links
crew-research lint
```

## Design Principles

- **Not required** — modules work standalone by copying them to the right location manually
- **Idempotent** — running twice produces the same output
- **Declarative input** — reads YAML manifests, doesn't require imperative scripts
- **Adapter-driven** — tool-specific behavior lives in adapter profiles, not in generator logic
- **Fail-fast** — unresolved references are errors, not warnings

## Future Considerations

- Per-project customization overlays (see issue #1)
- Remote module registries (resolve references from URLs)
- Diff mode (show what would change without writing)
- Watch mode (regenerate on source changes)
