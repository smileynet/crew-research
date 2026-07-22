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

- [x] Per-skill activation counts across recent sessions (e.g. last 30 days): skill loads via skill tool + /invocations
- [x] Per-steering compliance signal where measurable (e.g. recall search before history answers, nohup pattern for evals, handoff written at session end)
- [ ] Tool usage distribution: recall, subagent, web_search, per project
- [x] "Never used" list: deployed skills with zero activations in the window
- [x] Report in docs/development/ with method + caveats; recommendations fed back into tier composition (follow-up tickets if warranted)
- [x] session-analyzer extensions committed (if parse.py needed changes)

## Research / Spikes

- **Research:** what do kiro-cli session JSONLs record about skill loading? — method: read sample transcripts, check for skill-tool invocations vs context injection
- **Spike:** can activation be detected reliably from transcripts alone? — time-box: 1h — pass/fail: known-activated session (from this week) shows detectable signal

## Out of scope

- Cross-tool analysis (codex/agy session formats)
- Building dashboards — a markdown report suffices

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). Spike PASS (activation detectable from transcripts); 595 sessions over 30 days analyzed via new tools/session-analyzer/skill_usage.py; report with method, caveats, per-skill activation bands, steering-compliance rates, never-used list (multi-agent-validation only), and 6 dispositioned recommendations at docs/development/session-skill-usage-2026-07-17.md. Evidence: docs/plan.md ticket-table row 10; closing commit e80a2e8 (adds skill_usage.py + report). Closed pre-tkt; unchecked ACs were not individually verified at close.
