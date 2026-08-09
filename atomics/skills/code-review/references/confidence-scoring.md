# Confidence Scoring for Review Findings

Deterministic scoring applied AFTER generating findings. Score each finding based on
structural properties — no extra LLM call needed. Suppress findings below threshold.

## Scoring Rubric

| Property | +Score | Rationale |
|----------|--------|-----------|
| Cites specific line number + code snippet | +0.3 | Grounded finding, verifiable |
| References a documented rule (steering, AGENTS.md, convention file) | +0.2 | Rule-backed, not opinion |
| Category is correctness or security (not style/nit) | +0.2 | Higher consequence |
| Proposes a specific fix (not just "consider...") | +0.2 | Actionable |
| Affects changed lines (not surrounding context only) | +0.1 | Relevant to this PR |

**Maximum score: 1.0** (all properties present)

## Threshold

- **≥0.6**: Report to user (confident finding)
- **0.4–0.5**: Include with lower priority, marked as "low confidence"
- **<0.4**: Suppress (log for audit, never report)

## How to Apply

After generating review findings, scan each one:

1. Does it name a file and line? → +0.3
2. Does it cite a rule from steering/AGENTS.md/convention files? → +0.2
3. Is the category correctness, security, or data integrity? → +0.2
4. Does it include a code fix (not just description)? → +0.2
5. Is the issue in the changed diff lines? → +0.1

Sum the score. Apply threshold.

## Audit

When suppressing findings, log them as:
```
[SUPPRESSED score=0.3] {finding summary} — reason: style nit, no line cited, no fix
```

This allows periodic review of whether the threshold is correctly calibrated.

## When NOT to Score

- Security findings: always report regardless of score (override threshold)
- User explicitly asked for "thorough review" or "all findings"
- Spec axis findings: these answer "does it match the spec?" which is binary, not scorable

## Calibration

After 10+ reviews with scoring enabled, check:
- Are suppressed findings genuinely noise? (sample 5 suppressed, assess manually)
- Are reported findings consistently actionable? (track which get addressed)
- Adjust threshold ±0.1 if either check fails consistently
