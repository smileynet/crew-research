---
id: "108"
title: "Spike: queue-style subagent dispatch (start-next-as-slots-free)"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Queue-Style Subagent Dispatch

## Hypothesis

Current subagent dispatch uses rigid batches of 4 (platform limit per call). If one stage
finishes early, the slot sits idle until the entire batch completes. Queue-style dispatch —
start the next stage as soon as a slot frees — improves throughput without reducing
reliability.

## Baseline

- Current: dispatch 4 stages → wait for ALL 4 → validate → dispatch next 4.
- Problem: if 3 stages finish in 2min but one takes 8min, three slots are idle for 6min.
  For 8+ stage research tasks, this adds 10-20min of wasted wait.

## Spike design

Instead of batch-then-validate:
```
Queue: [A, B, C, D, E, F, G, H]
Slots: 4 concurrent max

T=0: dispatch A, B, C, D
T=2: A completes → validate A → dispatch E
T=3: B completes → validate B → dispatch F
T=5: C completes → validate C → dispatch G
T=8: D completes → validate D → dispatch H
T=10: E completes → validate E → done
...
```

**Implementation in steering:**
- Track a dispatch queue in `.scratch/dispatch-queue.yaml`
- After each subagent returns, validate immediately and dispatch the next pending stage
- Stop-on-failure: if 2+ consecutive failures, pause the queue and report

**Constraint:** The `subagent` tool API dispatches stages as a pipeline — stages with
`depends_on` run after their dependencies. This spike uses independent stages only
(research tasks where order doesn't matter).

## Validation criteria

- [ ] Queue dispatch completes faster than batch dispatch on a 6+ stage task
- [ ] Time savings measured (expect 20-40% on tasks with uneven stage durations)
- [ ] Failure handling works (stop after 2 consecutive failures)
- [ ] Results are identical to batch dispatch (same outputs, same quality)

## Reject if

- Platform API doesn't support dispatching single stages (must be pipeline)
- Overhead of per-stage dispatch calls exceeds time saved
- Queue tracking adds complexity without measurable throughput gain

## References

- Research: `.scratch/research/overlap-workflows.md`
- Subagent reliability steering: `~/.kiro/steering/subagent-reliability.md`
