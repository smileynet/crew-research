# Reference Exploration Template

Structured analysis template for exploring a repo or tool in .references/.

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

## Integration Points
How it connects to our project, via its interface surfaces:
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

When dispatched to explore a reference:

1. **Write output to file** at `.memory/{name}-reference.md` (with `studied_at` + `source` frontmatter per the skill)
2. **Return a brief summary** to the orchestrator (JTBD + key finding + top recommendation + file path)
3. **Do NOT return the full analysis inline** — file is the deliverable

## Rules

- Explore breadth-first (README, structure, entry points), then depth on interesting areas
- Cite file paths for every claim
- Non-obvious section gets the most attention — surface what a README won't tell you
- Flag anything that contradicts project assumptions
