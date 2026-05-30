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

## Source Hierarchy

| Priority | Source Type | Trust Level |
|:--------:|------------|-------------|
| 1 | Official docs, source code | High |
| 2 | Peer-reviewed papers, RFCs | High |
| 3 | Maintained wikis, reputable blogs | Medium |
| 4 | Stack Overflow, forums | Low (verify) |
| 5 | AI-generated summaries | Very low (always verify) |

## Rules

- Every claim must cite a source (URL, file path, or command output)
- If two sources conflict, report both with context
- Never present speculation as finding — mark uncertainty explicitly
- Check at least 3 sources before concluding
- Prefer primary sources over summaries

## Output Format

```
## Findings: [question]

### Answer
[Direct answer, 1-3 sentences]

### Evidence
- [Source 1]: [what it says]
- [Source 2]: [what it says]

### Gaps
- [What couldn't be confirmed]

### Recommendation
[What to do based on findings]
```

## Anti-Patterns

- Answering from memory without checking sources
- Citing one source as definitive
- Presenting "likely" as "confirmed"
- Stopping at the first result that seems right
- Mixing findings with recommendations without separating them
