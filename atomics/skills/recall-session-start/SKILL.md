---
name: recall-session-start
description: Session-start memory priming via recall CLI.
metadata:
  type: protocol
  invocation: agent-only
---

# Recall Session Start

At the beginning of each session, if `recall` is available on PATH:

1. Run `recall prime --wing <project>` (derive project from cwd)
2. Internalize the output as background context
3. Do not repeat the output to the user unless asked

If `recall` is not available, skip silently.
