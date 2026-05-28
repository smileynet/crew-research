---
name: research-dispatch
description: "Pattern for parallel research dispatch."
metadata:
  type: reference
  invocation: agent-only
---

# Research Dispatch

When you have multiple research topics to investigate:

1. **Dispatch one subagent per topic** — each writes findings to `.scratch/research/{topic-name}.md`
2. **After all complete** — synthesize into a single summary with: key findings, recommended approach, gaps, recommended spikes
3. **Promote lasting findings** to `.memory/` — delete scratch when captured

Format for each finding file:
```markdown
# {Topic Name}

## Key Facts
- ...

## Decisions Enabled
- ...

## Open Questions
- ...

## Sources
- ...
```
