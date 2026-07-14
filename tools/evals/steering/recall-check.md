
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

## When NOT to search

- The answer is already in the current session context (last ~20 messages)
- The question can be answered by reading a file or running a command
- The question is about code structure or current state, not past decisions
- The user is giving instructions, not asking about history

## Persist decisions

When a decision is made during the session:
```bash
recall add "We decided X because Y" --type decision
```
