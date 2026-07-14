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

## Red Flags in Transcripts

- "I'll try again" without changing approach → retry amplification
- Agent produces output for wrong audience → role confusion / split needed
- 3+ consecutive agent decisions without user input → rubber-stamp guard should fire
- "Done!" with no verification evidence → hallucinated success

## Subagent Limitations

When spawned as subagent, these tools are NOT available:
grep, glob, code, web_search, web_fetch, use_aws, todo_list

If a session shows an agent failing because it tried to use `web_search` as a subagent — that's a dispatch issue.

## Periodic Delta Regression (monthly)

Re-run 3-5 key skill evals to detect model catch-up. If a skill's delta drops below 0.5 from its original measurement, the model has internalized the behavior — consider demotion or merge.
