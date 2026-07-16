---
type: specification
title: "Tool Adapters Specification"
status: active
---

# Tool Adapters Specification

## Overview

Tool adapters map abstract operations (invoke agent, deploy skill, check output) to concrete CLI syntax for each supported tool. Shared by both the proof harness and eval harness.

## Directory Structure

```
tools/proofs/adapters/{tool}.yaml
```

Adapters are YAML profiles — one per tool.

## Adapter Format

```yaml
tool: kiro-cli
version_command: "kiro-cli --version"

invoke:
  command: "kiro-cli chat --no-interactive -a --wrap never --agent {agent} {query}"
  timeout: 90

agent:
  format: json
  location: ".kiro/agents/{name}.json"
  template: |
    {
      "name": "{name}",
      "description": "{description}",
      "tools": {tools},
      "allowedTools": {allowed_tools},
      "resources": {resources},
      "prompt": "{prompt}"
    }

skill:
  location: ".kiro/skills/{name}/SKILL.md"
  format: markdown-frontmatter

eager_context:
  location: ".kiro/steering/universal/{name}.md"
  format: markdown-frontmatter
  extra_frontmatter:
    inclusion: always

prompt:
  location: ".kiro/prompts/{name}.md"
  format: markdown-frontmatter
```

## Adapter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `tool` | Yes | Tool identifier |
| `version_command` | Yes | Command to get tool version for result tracking |
| `invoke.command` | Yes | Template for invoking an agent. Placeholders: `{agent}`, `{query}` |
| `invoke.timeout` | No | Default timeout in seconds |
| `agent.format` | Yes | Agent config format (`json`, `yaml`, `markdown-frontmatter`) |
| `agent.location` | Yes | Path template for agent configs |
| `agent.template` | Yes | Template for generating agent config files |
| `skill.location` | Yes | Path template for skill deployment |
| `eager_context.location` | Yes | Path template for eager-context deployment |
| `prompt.location` | No | Path for user-only skills (if tool separates them) |

## Supported Tools

### kiro-cli
```yaml
tool: kiro-cli
invoke:
  command: "kiro-cli chat --no-interactive -a --wrap never --agent {agent} {query}"
agent:
  format: json
  location: ".kiro/agents/{name}.json"
skill:
  location: ".kiro/skills/{name}/SKILL.md"
eager_context:
  location: ".kiro/steering/{scope}/{name}.md"
prompt:
  location: ".kiro/prompts/{name}.md"
```

### claude-code
```yaml
tool: claude-code
invoke:
  command: "claude --print --agent {agent} {query}"
agent:
  format: markdown-frontmatter
  location: ".claude/agents/{name}.md"
skill:
  location: ".claude/skills/{name}/SKILL.md"
eager_context:
  location: "CLAUDE.md"  # merged into single file
prompt:
  location: null  # prompts are skills with disable-model-invocation: true
```

### codex
```yaml
tool: codex
invoke:
  command: "codex --quiet --agent {agent} {query}"
agent:
  format: yaml
  location: ".codex/agents/{name}.yaml"
skill:
  location: ".codex/skills/{name}/SKILL.md"
eager_context:
  location: "AGENTS.md"  # merged into single file
```

## Harness Usage

The harness reads the adapter to:
1. Get tool version (`version_command`)
2. Deploy fixtures in the correct format/location (`agent.template`, `skill.location`)
3. Invoke the agent (`invoke.command`)
4. Parse output (strip ANSI, handle timeouts)

## Adding a New Tool

1. Create `tools/proofs/adapters/{tool}.yaml`
2. Fill in all required fields
3. Run existing proof definitions against the new adapter
4. Record results in `tools/proofs/results/{tool}/`
