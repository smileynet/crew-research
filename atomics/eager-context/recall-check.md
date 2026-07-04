---
name: recall-check
scope: worker
description: When to search cross-session memory before answering.
---

# Recall — Check Before Answering

When the user asks about past decisions, prior sessions, or project history, run `recall search "query"` BEFORE answering. Do not guess or fabricate past decisions.

## Trigger patterns

- "what did we decide about..."
- "last session...", "previously...", "remind me..."
- "continue from where we left off"
- "what was the decision on..."
- "have we discussed...", "did we already..."
- "what approach did we choose for..."

## Command

```bash
recall search "relevant query" --results 5
```

If results are relevant, cite them. If not, say you don't have that information.

## Persist decisions

When a decision is made during the session:
```bash
recall add "We decided X because Y" --type decision
```
