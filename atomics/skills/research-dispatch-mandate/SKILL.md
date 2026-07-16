---
name: research-dispatch-mandate
description: "Always-on mandate: research tasks with 2+ topics must dispatch parallel subagents rather than researching inline."
metadata:
  type: protocol
  invocation: agent-only
  practice: null
---

# Research Dispatch Mandate

When a task involves researching 2+ topics, **always dispatch subagents** — one per topic, batched appropriately.

## Rule: Dispatch, Don't Inline

When you identify multiple research questions (2+), you MUST:

1. **Decompose** into independent topics (one question per subagent)
2. **Dispatch** in batches of up to 4 stages (platform limit per call)
3. **Validate** results before dispatching the next batch
4. **Synthesize** in main context after all agents return

Do NOT research multiple topics sequentially in main context. Each topic you research inline consumes context budget that degrades subsequent work.

## Dispatch Rules

- **Max 4 subagents per dispatch call** (platform-enforced limit)
- If you have 5-8 topics: batch 1 (4), validate, batch 2 (remainder)
- If you have 9+ topics: split into batches of 4, validate between each
- **Agent role:** Use `kiro_default` (not `kiro` — that name doesn't resolve)
- If 2+ stages return empty in a batch: STOP, report the failure, switch to direct

## Prompt Template

Each subagent gets a small prompt (~100 words max):

```
Research: {one-sentence question}
Search the web for '{2-3 specific search queries}'.
Write findings to .scratch/research/{topic-slug}.md
Include: Summary (2-3 sentences), Details, Sources with URLs, Open Questions.
```

The subagent does the actual work (web search, file reading, synthesis) via tool calls. Your dispatch prompt stays small — that's what makes it reliable.

## When NOT to Dispatch

- **Data already in context** — don't re-dispatch what you already have
- **Single topic** — just research it directly
- **Corpus < 5 files, < 500 lines** — read directly, faster than dispatch overhead
- **Cross-topic synthesis** — do this yourself after subagents return (needs all findings together)

## After Subagents Return

Read all output files, then synthesize:
1. Key findings per topic (1-2 sentences each)
2. Cross-cutting themes or conflicts
3. Gaps (what couldn't be determined)
4. Recommendation based on combined evidence

## Why This Matters

Subagent dispatch preserves main context for the work that needs it (synthesis, decision-making, implementation). Research in main context is the #1 cause of context exhaustion — each web search result and file read accumulates, degrading quality on everything that follows.
