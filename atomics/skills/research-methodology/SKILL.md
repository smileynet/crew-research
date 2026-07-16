---
name: research-methodology
description: "Structured research process for investigating topics and producing findings. Use when exploring unfamiliar domains, evaluating options, or gathering evidence to inform decisions."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Research Methodology

## Process

1. **Frame** — state the question clearly. What do we need to know? What would change our decision?
2. **Survey** — broad search across multiple sources. Don't commit to first result.
3. **Evaluate** — assess source quality. Primary > secondary. Recent > old. Specific > general.
4. **Synthesize** — combine findings into a coherent answer with citations.
5. **Gap** — explicitly state what you couldn't confirm or find.

## Source Evaluation

When assessing an unfamiliar source, apply these criteria to place it in the authority hierarchy (see source-authority steering):

| Criterion | Question | Effect |
|-----------|----------|--------|
| **Accountability** | Named author/org with reputation at stake? | Anonymous → cap at L6 |
| **Recency** | Updated within the domain's decay window? | Stale → downgrade confidence |
| **Specificity** | Addresses your exact version/context? | Generic → note in relevance |
| **Corroboration** | Do independent sources agree? | Single-source → cap at "reported" |
| **Incentive** | Informing or selling? | Vendor marketing → note bias |
| **Traction** | Stars, forks, dependents, citations? | Prioritize investigation order; evaluate fit independently |

## Rules

- Check at least 3 sources before concluding
- Prefer primary sources over summaries
- Use traction signals to prioritize investigation order, not as quality verdicts
- Tag all citations per source-authority steering: `[L{n}:{confidence}]`

## Budget

- Cap at 8-10 web searches per research question
- After 3 consecutive searches returning no new information, stop and synthesize
- Prefer cloning repos (`--depth 1` to `.scratch/references/`) over fetching individual files via HTTP
- State gaps explicitly rather than searching indefinitely

## Output Format

Use the **research-output** skill's template — it is the canonical format for all research findings (frontmatter with topic/date/status/confidence; Summary, Findings, Sources with `[L{n}:{confidence}]` tags, Related Topics, Related Tools, Open Questions). Do not invent an inline structure; one format keeps findings reusable across sessions and consumable by other agents.

## Anti-Patterns

- Answering from memory without checking sources
- Citing one source as definitive
- Presenting "likely" as "confirmed"
- Stopping at the first result that seems right
- Mixing findings with recommendations without separating them

## References

- For parallel research dispatch pattern (subagent per topic), read [references/dispatch-pattern.md](references/dispatch-pattern.md)
