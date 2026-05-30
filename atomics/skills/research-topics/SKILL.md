---
name: research-topics
description: "Dispatch parallel research across a list of topics. Each topic gets a subagent that writes findings to .scratch/research/. Synthesizes results after all complete."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Research Topics

Dispatch parallel subagents to research a list of topics.

## Input

Accept topics from:
- The user's message (numbered list or comma-separated)
- A file (if user points to one, e.g., `.memory/research-topics.md`)

## Execution

For each topic, dispatch a subagent (max 4 per batch):

**Subagent task:** Research {topic}. Write findings to `.scratch/research/{topic-slug}.md` using this format:

```markdown
# {Topic}

## Key Facts
- ...

## Decisions Enabled
- ...

## Open Questions
- ...

## Sources
- ...
```

## After All Complete

1. Read all `.scratch/research/*.md` files
2. Synthesize into `.memory/research-synthesis.md`:
   - Key findings per topic (1-2 sentences each)
   - Recommended approach (if topics inform a decision)
   - Gaps remaining (what still needs investigation)
   - Recommended spikes (if any finding needs validation)
3. Report summary to user

## Rules

- Max 4 subagents per batch. If >4 topics, run in sequential batches.
- If `.scratch/research/{topic-slug}.md` already exists, skip (already researched).
- Each subagent should use web search for external topics, codebase exploration for internal ones.
- Keep findings factual — cite sources, flag uncertainty.
