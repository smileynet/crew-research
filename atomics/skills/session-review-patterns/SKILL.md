---
metadata:
  type: reference
  invocation: both
  practice: null
name: session-review-patterns
description: "Patterns for reviewing kiro-cli session transcripts. Use when analyzing sessions for protocol compliance, performance issues, or skill improvements."
---

# Session Review Patterns

## What to Look For

### Protocol Compliance
- Did workers emit structured DONE/BLOCKED/FAILED signals?
- Did orchestrator verify results before proceeding?
- Was verification actually run (not just claimed)?
- Were assumptions surfaced in DONE signals?

### Performance Issues
- Context overflow (agent forgets earlier instructions mid-session)
- Repeated failures without strategy change (retry amplification)
- Agent doing research inline instead of dispatching to subagent
- Agent asking open-ended questions instead of researching first

### Skill/Steering Issues
- Skills triggering when irrelevant (vague descriptions)
- Skill too broad (covers multiple concerns → split signal)
- Steering contradictions (two files give opposite guidance)

## Subagent Limitations

When spawned as subagent, these tools are NOT available:
grep, glob, code, web_search, web_fetch, use_aws, todo_list

If a session shows an agent failing because it tried to use `web_search` as a subagent — that's a dispatch issue. Dispatch research tasks from the main agent instead.

## Red Flags in Transcripts

- "I'll try again" without changing approach → retry amplification
- Agent produces output for wrong audience → role confusion / split needed
- 3+ consecutive agent decisions without user input → rubber-stamp guard should fire
- "Done!" with no verification evidence → hallucinated success
- Agent modifies .kiro/agents/ or .kiro/steering/ → deniedPaths violation
