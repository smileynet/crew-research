---
name: recall-session-start
description: Session-start memory priming via recall CLI.
metadata:
  type: protocol
  invocation: agent-only
  practice: null
---

# Recall Session Start

At the beginning of each session, if `recall` is available on PATH:

1. Check staleness: read `~/.recall/last_ingest` — if missing or >24h old, tell the user:
   "Recall memory is stale (last ingest: [date] or never). Run `recall ingest ~/.kiro/sessions/cli` to update."
2. Run `recall prime` (wing auto-detects from cwd)
3. Internalize the output as background context
4. Do not repeat the prime output to the user unless asked

If `recall` is not available, skip silently.
