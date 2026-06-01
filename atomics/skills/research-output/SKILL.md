---
name: research-output
description: "Structured output format for research findings. Use when producing research results, investigation reports, or any findings that should be reusable across sessions. Ensures sources, related topics, and tools are always captured alongside the findings."
metadata:
  type: reference
  invocation: both
  practice: null
  params:
    output_path: ".scratch/research"
---

# Research Output Format

Produce research findings in this structure so they are reusable regardless of topic.

## Template

```markdown
---
topic: {concise topic name}
date: {YYYY-MM-DD}
status: draft | complete | superseded
confidence: high | medium | low
---

# {Topic}

## Summary
{2-3 sentence answer to the research question}

## Sources
- [L{n}:{confidence}] [{title or description}]({url or file path}) — {relevance + evaluation note}
- [L{n}:{confidence}] [{title or description}]({url or file path}) — {relevance + evaluation note}

## Related Topics
- {topic} — {why it's related, what to explore next}
- {topic} — {connection to this research}

## Related Tools & Resources
- {tool/library/service} — {what it does, when to use it}
- {resource} — {how it helps}

## Findings
{Unstructured, topic-specific content. No imposed format.
Use whatever structure fits: prose, tables, lists, code blocks.
This is where the actual research lives.}

## Open Questions
- {What couldn't be determined}
- {What needs further investigation}
```

## Rules

- **Sources are mandatory and tagged.** Every finding must trace to a source with authority level and confidence (see source-authority steering). Tag with `[L{n}:{confidence}]` when output will be consumed by other agents. Always include evaluation reasoning regardless of tag format.
- **Related Topics capture the frontier.** What would you research NEXT? What adjacent areas did you notice?
- **Related Tools are actionable.** Not "there are tools" — name them, say what they do.
- **Summary answers the question first.** Reader gets value from the first 3 sentences.
- **Confidence is honest.** High = verified from multiple sources. Medium = single source or inference. Low = speculation.
- **Open Questions prevent false completeness.** Always state what you DON'T know.

## Subagent Usage

When invoked as a subagent (delegated by a lead/orchestrator):

1. **Write the output to a file** at `{{params.output_path}}/{topic-slug}.md`
2. **Return the Summary + Sources** in your response to the orchestrator (not the full document)
3. **The file IS the deliverable** — the orchestrator can point other agents to it
4. **Do NOT return the full findings inline** — it bloats the orchestrator's context. File path + summary is sufficient.

Example subagent response:
```
Research complete. Findings written to .scratch/research/redis-vs-memcached.md

Summary: Redis is preferred for our use case — it supports persistence,
pub/sub, and complex data structures. Memcached is faster for simple
key-value caching but lacks durability.

Sources: [L4:verified] Redis docs, [L4:verified] AWS comparison, [L5:established] benchmark paper
Open questions: 1 (cluster mode performance at our scale)
```

## When NOT to Use This Format

- Quick factual lookups (just answer inline)
- Code examples (just show the code)
- Single-source answers (cite inline, no file needed)

Use this format when: the research took multiple sources, produced findings worth keeping, or will be referenced by other agents/sessions.
