---
id: "106"
title: "Spike: trajectory scoring — evaluate tool-call sequences without LLM"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Trajectory Scoring

## Hypothesis

Some eval criteria can be checked by examining the SEQUENCE of tool calls rather than the
final output. "Did the agent verify before claiming done?" = did it call `shell` (running
tests) before its final message? This is deterministic, fast, and free.

Inspired by mastra's trajectory evaluation pattern.

## Baseline

- Current: all scoring requires LLM judgment of the final output or full transcript.
- Problem: "did it run tests?" is a tool-call-sequence question, not a prose question.
  An LLM judge reading the full transcript is overkill and slow.

## Spike design

Define trajectory predicates:
```yaml
trajectory_checks:
  - name: "verified-before-done"
    pattern: "shell.*SCORE"  # shell call exists before final scoring
    require: present
  - name: "read-before-write"
    pattern: "read.*write"   # read call before any write call
    require: present
  - name: "no-force-push"
    pattern: "git push --force"
    require: absent
```

**Implementation:**
1. Extract tool-call sequence from session output (already captured in eval outputs)
2. Apply predicates (regex over the ordered tool-call list)
3. Score: all predicates pass = trajectory score 5, failures = score 1-4 proportional

**Use cases:**
- verification-protocol: did it run checks before reporting done?
- feedback-loop-debugging: did it build a signal before attempting fixes?
- git-protocol: did it avoid destructive operations?

## Validation criteria

- [ ] Extract tool-call sequences from existing eval outputs (prove data is available)
- [ ] Define 3-5 trajectory predicates for existing eval definitions
- [ ] Trajectory scores agree with LLM judge verdicts ≥90% on verification-protocol evals
- [ ] Scoring time <1s per definition (vs minutes for LLM judging)

## Reject if

- Tool-call data isn't reliably captured in eval outputs (data not available)
- Predicates are too brittle (tool names change, ordering isn't meaningful)
- Agreement with judge <80% (trajectory is a poor proxy for the actual criterion)

## References

- Mastra trajectory eval: `.references/mastra/packages/evals/src/`
- Research: `.scratch/research/overlap-evals.md`
