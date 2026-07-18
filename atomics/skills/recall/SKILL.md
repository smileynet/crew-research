---
name: recall
description: "Cross-session memory recall. Use when asked about past decisions, prior work, what was discussed previously, or to continue from where a session left off. Use to persist decisions and lessons learned. Trigger: \"what did we decide\", \"last session\", \"previously\", \"recall\", \"remind me\", \"continue from where we left off\", \"what was the decision\"."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Recall — Cross-Session Memory

## When to use

- User asks about a past decision, prior discussion, or previous session
- User wants to continue work from a prior session
- User asks "what did we decide about X" or "remind me"
- You need project context before starting work
- You've made a decision or learned something worth persisting

## Search (before answering about the past)

```bash
recall search "query" --results 5
```

Search is cross-project by default. Add `--wing name` to scope to one project, or `--room decisions` to narrow by topic.

**Rules:**
- Search BEFORE answering questions about past work — do not guess
- If results aren't relevant, say so and proceed without them
- Quote the source when using recalled content

## Write-back (persist decisions and lessons)

```bash
recall add "We decided X because Y" --room decisions --type decision
recall add "Learned: approach Z doesn't work because..." --type lesson
```

Wing auto-detects from the current working directory. Pass `--wing name` only to override.

**Types:** `decision` | `fact` | `lesson` | `preference`

**Rules:**
- Persist decisions immediately when made — don't batch
- Keep entries under 200 words — distill, don't dump
- Include rationale, not just the decision
- One fact per entry

## Prime (session start — if instructed by steering)

```bash
recall prime
```

Wing auto-detects from cwd. Outputs recent memories + relevant context. Internalize but don't repeat verbatim to the user.

## Fallback (when recall is unavailable)

If `recall` is not on PATH, exits non-zero, or returns "No results found":
1. Tell the user: "I can't check past sessions right now"
2. Answer from current context only
3. Never fabricate past decisions — say you don't know

## Full CLI Reference

For install, ingest cron setup, and the complete command table, read [references/cli-reference.md](references/cli-reference.md).
