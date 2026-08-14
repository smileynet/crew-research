---
id: "105"
title: "Spike: structured judge output schema for per-criterion scoring"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Structured Judge Output Schema

## Hypothesis

Requiring judges to output structured JSON (per-criterion scores + reasoning) instead of
free-text will enable automated aggregation, failure pattern detection, and cross-run
comparison — things currently impossible with prose judge output.

Inspired by mastra's Zod-based eval scorers that return typed results with breakdowns.

## Baseline

- Current: judges output `SCORE: N` + `REASON: free text`. Parsing is regex-based.
- Problem: "REASON: The agent did well on planning but missed verification" — which
  criterion failed? Can't aggregate across runs without manual reading.

## Spike design

Judge prompt requests structured output:
```json
{
  "score": 4,
  "criteria": {
    "planning": {"score": 5, "met": true, "note": "asked clarifying questions"},
    "verification": {"score": 2, "met": false, "note": "no evidence cited"},
    "scope": {"score": 4, "met": true, "note": "changes limited to task"}
  },
  "summary": "Strong planning, weak verification"
}
```

**Harness changes:**
- Judge prompt includes the schema definition
- Parse JSON from judge output (fallback to current regex if JSON fails)
- Write structured results to `scores.jsonl` (backward-compatible: add fields, don't remove)
- Aggregation: can now report "verification fails in 60% of runs" across definitions

## Validation criteria

- [ ] Judge prompt produces valid JSON output ≥90% of the time
- [ ] Per-criterion scores enable "which criterion fails most?" analysis
- [ ] Backward compatible: old scores.jsonl consumers still work (new fields are additive)
- [ ] Cross-run comparison possible (same criteria keys across runs)
- [ ] Fallback to regex parsing when JSON output fails

## Reject if

- Judges produce invalid JSON >20% of the time (unreliable)
- Structured output changes judge behavior (different scores than free-text)
- Schema maintenance overhead exceeds the analysis benefit

## References

- Mastra eval scorers: `.references/mastra/packages/evals/src/`
- Research: `.scratch/research/overlap-evals.md`
- Current judge output: `tools/evals/harness/run.sh` L540-580
