---
id: "109"
title: "Spike: formalized failure semantics table per orchestration pattern"
status: open
blocked_by: []
env: either
priority: normal
---

# Spike: Formalized Failure Semantics

## Hypothesis

Making failure handling explicit per orchestration pattern (table of: on-failure action,
on-empty action, recovery path) will reduce ad-hoc failure handling and make the
subagent-reliability steering more actionable.

Currently the steering says "design for partial failure" but doesn't specify what each
failure mode's response should be per pattern type.

## Spike design

Add a failure semantics table to subagent-reliability steering:

| Pattern | On empty response | On error/timeout | On thin output | Recovery |
|---------|------------------|-----------------|---------------|----------|
| Research dispatch (independent) | Skip, note gap | Retry once, then skip | Flag as partial | Read directly if <500 lines |
| Sequential pipeline (dependent) | Block, retry | Retry with smaller prompt | Validate completeness | Split stage further |
| Validation/review | Treat as "no issues found" | Retry (critical path) | Request re-run with specifics | Escalate to main context |
| File extraction | Skip file, continue | Log and continue | Compare output size vs input | Manual read for missed files |

**For each pattern, define:**
1. What constitutes failure (empty, error, thin, wrong shape)
2. Immediate response (retry, skip, block)
3. Escalation path (when to stop retrying and change strategy)
4. How to report the gap in the final deliverable

## Validation criteria

- [ ] Table covers all orchestration patterns used in crew-research
- [ ] Each cell has a concrete action (not "handle appropriately")
- [ ] Steering update is ≤20 lines (table format, not prose)
- [ ] Next subagent dispatch session follows the table (observable behavior change)

## Reject if

- Table is too rigid (patterns need case-by-case judgment that can't be tabled)
- Adding the table makes the steering file too long (currently ~100 lines)

## References

- Research: `.scratch/research/overlap-workflows.md`
- Current steering: `~/.kiro/steering/subagent-reliability.md`
