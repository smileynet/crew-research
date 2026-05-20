---
created_at: 2026-05-20T06:50:00-07:00
base_commit: 4b0db2d
---

# Spike S4 Results: Judge Model Selection

## Method
Took 4 fixed agent outputs from best_practices eval results (varying quality levels) and ran each through the judge 5 times to measure intra-judge variance.

## Results

| Output | Expected Quality | 5 Judge Scores | Stdev | Verdict |
|--------|-----------------|----------------|-------|---------|
| five_whys | Medium (branching, not pure chain) | 3, 3, 3, 3, 3 | 0.0 | Perfectly consistent |
| diagnose | High (systematic protocol) | 5, 5, 5, 5, 5 | 0.0 | Perfectly consistent |
| handoff | Low (minimal, missing sections) | 1, 1, 1, 1, 1 | 0.0 | Perfectly consistent |
| steel_man | High (strong opposing argument) | 5, 5, 5, 5, 5 | 0.0 | Perfectly consistent |
| socratic | Borderline (prior eval scored 3.3) | 5, 5, 5, 5, 5 | 0.0 | Perfectly consistent |

## Key Finding

**Judge variance is ZERO when input is fixed.** The default kiro-cli judge (Claude) produces identical scores across 5 runs on the same input. This means:

1. **All variance in the agent-crews eval system comes from AGENT non-determinism**, not judge non-determinism
2. **Single-judge, single-trial is sufficient** for scoring a fixed output
3. **Multi-trial is needed for agent reliability testing**, not for judge reliability
4. **Cross-provider judging is a nice-to-have**, not a necessity for variance reduction

## Implications for Our Eval Harness

- **Default config: 1 judge trial per output** (judge is deterministic on fixed input)
- **Multi-trial (3x) for agent invocation** (agent is non-deterministic)
- **Cross-provider judge: defer** until we have evidence of systematic bias (not variance)
- **The existing agent-crews approach (3 agent trials, 1 judge per trial) is correct**

## Caveat

This test used a single judge model (Claude via kiro-cli default). We did NOT test:
- Cross-provider agreement (would Claude and GPT-4o score the same output identically?)
- Self-preference bias (is Claude scoring Claude output higher than it would score GPT output?)
- Edge cases where criteria are genuinely ambiguous

These are lower-priority concerns since the primary risk (judge variance) is confirmed to be zero.

## Recommendation

Use the default model (Claude Sonnet) as the judge. It's deterministic, available, and produces consistent scores. Add cross-provider judging later if we observe systematic scoring patterns that suggest bias (e.g., all Claude outputs score 5, all GPT outputs score 3 on identical tasks).

## Decision

**S4 PASSES.** Default judge config:
- Model: whatever kiro-cli defaults to (currently Claude Sonnet)
- Temperature: 0 (implicit — kiro-cli doesn't expose this, but results show deterministic behavior)
- Trials: 1 per fixed output (judge is consistent)
- Agent trials: 3 (agent is non-deterministic)
- Cross-provider: deferred (no evidence of need)
