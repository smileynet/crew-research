# Prototype Dispatch

Use when a design question needs its own session — too large for a subagent, requires exploration, iteration, or significant context.

## When to use

- The question requires building something to answer ("does this architecture work end-to-end?")
- Estimated effort exceeds what a subagent can do in one shot (~15 min+)
- The work needs its own context budget (reading codebases, iterating on implementations)

## Process

1. Propose: state the question, hypothesis, and time-box
2. Ask: "This needs a prototype. Run in a new session or queue for later?"
3. Write dispatch doc to `.scratch/spikes/{slug}.md`
4. If results exist (`.scratch/spikes/{slug}-results.md`), incorporate into decision
5. Track in decision table with confidence "Pending prototype" until results arrive

## Template

```markdown
---
type: prototype
status: pending
parent: grill-with-docs
question: "Does X actually work when Y?"
return_to: .scratch/spikes/{slug}-results.md
---

# Prototype: {title}

## Question
{The specific question this prototype answers}

## Hypothesis
{What we expect to find}

## Method
{Steps to execute — specific, actionable}

## Constraints
- Time-box: {duration}
- Scope: {what's in/out}

## Return Format
Write results to `.scratch/spikes/{slug}-results.md`:
- **Verdict**: confirmed / refuted / inconclusive
- **Evidence**: what you observed (code, test output, measurements)
- **Implications**: how this affects the design decision

## Context
{Relevant files, prior decisions, constraints the next session needs}
```
