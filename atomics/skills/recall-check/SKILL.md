---
name: recall-check
description: When to search cross-session memory before answering.
metadata:
  type: protocol
  invocation: agent-only
  practice: null
---

# Recall Gate — Search Before Answering History Questions

GATE: when the user asks about past decisions, prior sessions, or project history, you MUST run `recall search` BEFORE answering. An answer about the past without a search in this session is a violation — do not guess or fabricate past decisions.

## Gate workflow

1. **Classify** — is this a history question? Trigger phrasings:
   - "what did we decide about...", "what was the decision on..."
   - "last session...", "previously...", "remind me..."
   - "continue from where we left off"
   - "have we discussed...", "did we already..."
   - "what approach did we choose for..."
2. **Search** — before composing the answer:
   ```bash
   recall search "relevant query" --results 5
   ```
3. **Answer with evidence** — cite relevant results. If nothing relevant returns, say you don't have that record. Never present a guess as a memory.

## Skip conditions — the ONLY exemptions

- The answer is already in the current session context (last ~20 messages)
- Reading a file or running a command answers it (current state, not history)
- The user is giving instructions, not asking about history

If none apply, the search is mandatory — "probably remember" and "seems minor" are not skip conditions.

## Violations (not acceptable)

- Stating "we decided X" with no fresh `recall search` this session
- Answering from training-data-style recall instead of the recall CLI
- Skipping the search because the session feels short or the question small

## Persist decisions

When a decision is made during the session:
```bash
recall add "We decided X because Y" --type decision
```
