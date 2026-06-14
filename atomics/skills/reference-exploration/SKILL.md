---
name: reference-exploration
description: "Structured exploration of a repo or tool in .references/. Use when dispatched to analyze a third-party codebase, library, or tool to surface its purpose, patterns, interfaces, and follow-up recommendations."
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

## JTBD
{What user problems this solves — situations, not features.}

## Decisions and Tradeoffs
{Key architectural choices. What was chosen, what was sacrificed, why.}

## Non-obvious
{Gotchas, edge cases, hidden complexity, failure modes, subtle interactions.
This is the highest-value section — be specific and cite file paths.}

## Prior Art
{Known patterns implemented. Deviations from standard approaches. Influences.}

## Audience
{Who uses this. Knowledge level assumed. Different audiences for different layers.}

## Conventions
{Local rules. Naming patterns. Style deviations. Internal protocols.}

## Interface Surfaces
- **CLI**: {commands, flags, entry points}
- **API**: {exports, public functions, key types}
- **Config**: {config files, env vars, settings}
- **Extension points**: {plugins, hooks, adapters}

## Recommendations

### Research Topics
- {Topic to investigate further} — {why it matters}

### Testing Spikes
- {What to test} — {hypothesis to validate}

### Adoption Considerations
- {Pros of adopting/using this}
- {Risks or concerns}
- {Effort estimate for integration}
```

## Subagent Usage

When dispatched by a lead to explore a reference:

1. **Write output to file** at `{{params.output_path}}/{repo-slug}.md`
2. **Return a brief summary** to the orchestrator:
   - JTBD (1 sentence)
   - Key non-obvious finding (1 sentence)
   - Top recommendation (1 sentence)
   - File path for full details
3. **Do NOT return the full analysis inline** — file is the deliverable

## Rules

- Explore breadth-first (README, structure, entry points), then depth on interesting areas
- Cite file paths for every claim (e.g., "src/router.ts:42")
- Don't read every file — focus on public interfaces and architecture
- Non-obvious section gets the most attention — surface what a README won't tell you
- Flag anything that contradicts our assumptions
