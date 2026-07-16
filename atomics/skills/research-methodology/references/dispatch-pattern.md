# Research Dispatch Pattern

When you have multiple research topics to investigate:

1. **Dispatch one subagent per topic** — each writes findings to `.scratch/research/{topic-name}.md`
2. **After all complete** — synthesize into a single summary with: key findings, recommended approach, gaps, recommended spikes
3. **Promote lasting findings** to `.memory/` — delete scratch when captured

## Format for each finding file

Each subagent writes its finding file in the **research-output** skill's canonical template (frontmatter + Summary, Sources, Related Topics, Findings, Open Questions). Include the template's section list in the dispatch prompt so subagents don't improvise structure.

## Rules

- Keep dispatch prompts small (< 1K tokens) — use file paths, not inline data
- Validate each result for completeness before synthesizing
- If subagent fails, retry once with smaller scope, then read directly
