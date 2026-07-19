---
name: session-analysis
description: "Run and interpret session transcript analysis — skill activation rates, steering compliance, tool usage across kiro sessions. Use when measuring skill field usage, checking recall-check compliance, reviewing what skills actually activate, or judging skill retirement. Trigger: session review, skill usage, field compliance, steering compliance, never activated, session:skills, session:parse."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Session Analysis

Parses `~/.kiro/sessions/cli` transcripts. Both tasks REQUIRE `--days`:

```bash
mise run session:skills -- --days 30    # skill activation + steering compliance (main report)
mise run session:parse -- --days 30     # raw transcript parse (--output FILE for JSON to disk)
```

Direct: `python tools/session-analyzer/skill_usage.py --days N` (JSON to stdout).

## Reading the skill_usage report

| Key | Meaning / how to act |
|-----|---------------------|
| `sessions` / `crew_research_dev_sessions` | window size; dev sessions are excluded from field-usage judgments (we trigger our own skills) |
| `skill_activations_sessions` | sessions where each skill's content entered context — the field-usage number |
| `never_activated` | deployed skills with zero activations in the window — retirement CANDIDATES, not verdicts (check the skill was actually deployed and correct for the whole window first; see multi-agent-validation precedent, t09 rec #5) |
| `activation_signal_kinds` | how activation was detected — weight explicit loads over incidental mentions |
| `steering_compliance.history_questions` vs `.history_q_with_recall_search` | **recall-check compliance ratio** — the ticket 23 metric. Baseline 21% (2026-07-17, 60/284) |
| `recall_check_compliance` | convenience block (added ticket 23): same counters plus precomputed `rate` and the baseline string — cite this in compliance reports |
| `steering_compliance.eval_run_sessions` vs `.eval_run_with_nohup` | eval-execution steering compliance |
| `sessions_per_project` | denominator context — low-session projects give noisy rates |

## Interpretation rules

- **Windows matter:** ≥30 days for retirement judgments; ≥7 days for compliance deltas; a 2-day window is a smoke test, not evidence.
- **Compare like windows:** compliance measured over N days compares against a baseline of similar N (weekday mix shifts usage).
- **Skill fixed mid-window?** Restart the clock — activations before the fix don't count for the fixed version (frontmatter/body breakage precedent: multi-agent-validation).
- Report rates WITH raw counts (42/98, not "43%") — small denominators must be visible.

## When to run

- Ticket 23 measurement (recall-check compliance vs 21% baseline)
- Monthly skill portfolio review (retirement candidates, trigger-space overlaps like planning-cycles vs sdd — t09 rec #2)
- After any steering gate change (did compliance move?)
