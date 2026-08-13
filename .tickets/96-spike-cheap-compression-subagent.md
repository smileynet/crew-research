---
id: "96"
title: "Spike: cheap-model compression for subagent dispatch context"
status: open
blocked_by: []
env: personal
spec: "eval-harness"
---

# Spike: Cheap-Model Compression for Subagent Dispatch Context

## Hypothesis

Pre-compressing large context (subagent outputs, research findings) with a cheap/fast model
before the frontier model processes it will preserve context budget while maintaining info
quality. Subagent-reliability steering: prompt >5K tokens → ~90% failure. Compression could
enable larger payloads. Academic finding: compression IMPROVED accuracy by 21.4%
(LongLLMLingua) because removing noise helps the frontier attend to what matters.

## Baseline to measure against

1. **Current state**: Write-Then-Read pattern. No compression. Manual budget management.
2. **Measurements**: Subagent success rate by prompt size. Context remaining after reading
   4 research outputs (~800-2000 lines each). Synthesis quality from raw vs compressed.

## Spike design

### Approach A: Script-Mediated Compression

Script (`tools/compress-context.sh`) that calls a cheap model via kiro-cli `--no-interactive`:
"Summarize preserving decisions, file paths, findings, constraints. Remove exploration,
intermediate reasoning, raw tool output. Target 20% of original."

### Approach B: Zero-Model Compression (Claude Code pattern)

- Output >N lines → write to disk + 2-line summary in context
- Incremental structured notes in `.scratch/session-notes.md`
- At phase boundaries, read notes instead of raw files

### Measurement

Same research task three ways: raw read (control), Approach A, Approach B.
Evaluate: completeness (facts retained), accuracy, actionability.

## Validation criteria

- [ ] Approach A: ≥3× size reduction retaining ≥90% key facts
- [ ] Approach B: equivalent task quality to raw reading
- [ ] Context budget savings quantified
- [ ] Compression latency <30s (>60s = too slow)
- [ ] At least one approach demonstrates better synthesis than raw reading

## Reject if

- Compression loses critical details changing decisions (>10% fact loss)
- kiro-cli lacks ability to invoke a cheap model programmatically (platform blocker)
- Compression latency exceeds time saved by shorter frontier processing

## References

- Research: `.scratch/research/cheap-model-compression.md`
- Subagent reliability: `~/.kiro/steering/subagent-reliability.md`
- Context budget awareness: `~/.kiro/steering/context-budget-awareness.md`
