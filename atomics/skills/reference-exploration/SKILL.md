---
name: reference-exploration
description: "Structured exploration of a repo or tool in resources/. Use when dispatched to analyze a third-party codebase, library, or tool to surface its purpose, patterns, interfaces, and follow-up recommendations."
metadata:
  type: reference
  invocation: both
  practice: null
  params:
    output_path: ".scratch/research"
---

# Reference Exploration

Produce a structured analysis of a repo/tool that enables informed decisions without re-reading the source.

## Template

```markdown
---
topic: {repo or tool name}
date: {YYYY-MM-DD}
status: complete
type: reference-exploration
---

# {Repo/Tool Name}

## Purpose
{What this does in 2-3 sentences. What problem it solves.}

## Key Dependencies
- {dependency} — {what role it plays}
- {dependency} — {why it's needed}

## Architecture / Patterns
- {Pattern observed} — {where and why}
- {Convention used} — {how it's applied}

## Interface Surfaces
- **CLI**: {commands, flags, entry points}
- **API**: {exports, public functions, key types}
- **Config**: {config files, env vars, settings}
- **Extension points**: {plugins, hooks, adapters}

## Notable Implementation Details
{Anything surprising, clever, or important to understand.
Not a full code review — just what someone would need to know
to use, extend, or integrate with this.}

## Recommendations

### Research Topics
- {Topic to investigate further} — {why it matters}
- {Adjacent area} — {connection to our work}

### Testing Spikes
- {What to test} — {hypothesis to validate}
- {Integration to try} — {what it would prove}

### Adoption Considerations
- {Pros of adopting/using this}
- {Risks or concerns}
- {Effort estimate for integration}
```

## Subagent Usage

When dispatched by a lead to explore a reference:

1. **Write output to file** at `{{params.output_path}}/{repo-slug}.md`
2. **Return a brief summary** to the orchestrator:
   - Purpose (1 sentence)
   - Key finding (1 sentence)
   - Top recommendation (1 sentence)
   - File path for full details
3. **Do NOT return the full analysis inline** — file is the deliverable

Example response to orchestrator:
```
Exploration complete. Written to .scratch/research/fastify-cli.md

Purpose: CLI scaffolding tool for Fastify projects.
Key finding: Uses a plugin architecture with decorators — similar to our adapter pattern.
Recommendation: Spike whether their plugin loader could replace our manual adapter registration.
```

## Rules

- Explore breadth-first (README, structure, entry points), then depth on interesting areas
- Cite file paths for every claim (e.g., "src/router.ts:42")
- Don't read every file — focus on public interfaces and architecture
- Flag anything that contradicts our assumptions
