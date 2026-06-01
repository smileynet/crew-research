# ADR 0004: Session Review Methodology

## Status
Accepted

## Context
We needed a way to assess whether crew-research skills and steering are actually improving agent behavior in real sessions. Without measurement, we can't tell if changes help or hurt.

## Decision
Adopt a two-phase session review methodology:

1. **Quantitative extraction** (`tools/session-analyzer/parse.py`) — automated metrics: tool call frequency, shell command patterns, error counts, temporal trends (intra-session learning, cross-session improvement).

2. **Qualitative deep dive** (`tools/session-analyzer/extract_batches.py` + subagent fanout) — 6 parallel subagents review all conversations against a 6-dimension rubric (task completion, steering compliance, efficiency, self-correction, tool appropriateness, user friction).

Cadence: weekly, scoped to last 7 days. First review used 2-day window during stable adoption period.

## Consequences

**Good:**
- Comprehensive coverage (all sessions reviewed, not sampled)
- Temporal baseline enables tracking improvement over time
- Subagent fanout scales to any volume
- Findings directly map to skill/steering changes

**Bad:**
- Batch extraction loses some context (truncated to fit subagent windows)
- No token count data in JSONL format (can't measure context efficiency directly)
- Subagent reviewers may miss subtle patterns that require full conversation context

## Alternatives Considered

- **Manual sampling** — accurate but doesn't scale, misses patterns in unsampled sessions
- **Automated heuristics only** — fast but can't assess reasoning quality or user satisfaction
- **LLM-as-judge on full transcripts** — too expensive (288MB of data per review period)

## Baseline (2026-06-01)

| Metric | Value |
|--------|-------|
| Task Completion | 4.2/5 |
| Steering Compliance | 3.3/5 |
| Efficiency | 2.9/5 |
| Self-Correction | 3.5/5 |
| Tool Appropriateness | 3.6/5 |
| User Friction | 2.8/5 |
| Blocking Start-Process (intra, first→second half) | 115 → 16 |
| Tool reuse (cross-session, per convo) | 2.7 → 8.5 |
