---
id: "10"
title: "Session logs reveal which skills and tools actually get used"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Session logs reveal which skills and tools actually get used

## What to build

An evidence-based usage report answering: which deployed skills actually activate in real sessions? Which are never loaded? Which tools (recall, subagent dispatch, steering-mandated commands) get invoked, and do agents follow the steering that references them? This grounds tier composition and retirement decisions in field data instead of review judgment.

## Context

- **Relevant files:** `tools/session-analyzer/parse.py` (existing transcript parser, v2/v3 session formats), `~/.kiro/sessions/cli/` (~2,900 JSONL files)
- **Relevant decisions:** R1 verdicts assumed value from content review — this validates against actual usage
- **Prior art:** `mise run session:parse` exists; check what it already extracts before extending

## Acceptance criteria

- [ ] Per-skill activation counts across recent sessions (e.g. last 30 days): skill loads via skill tool + /invocations
- [ ] Per-steering compliance signal where measurable (e.g. recall search before history answers, nohup pattern for evals, handoff written at session end)
- [ ] Tool usage distribution: recall, subagent, web_search, per project
- [ ] "Never used" list: deployed skills with zero activations in the window
- [ ] Report in docs/development/ with method + caveats; recommendations fed back into tier composition (follow-up tickets if warranted)
- [ ] session-analyzer extensions committed (if parse.py needed changes)

## Research / Spikes

- **Research:** what do kiro-cli session JSONLs record about skill loading? — method: read sample transcripts, check for skill-tool invocations vs context injection
- **Spike:** can activation be detected reliably from transcripts alone? — time-box: 1h — pass/fail: known-activated session (from this week) shows detectable signal

## Out of scope

- Cross-tool analysis (codex/agy session formats)
- Building dashboards — a markdown report suffices
