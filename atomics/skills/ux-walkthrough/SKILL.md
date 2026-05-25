---
name: ux-walkthrough
description: >
  Step-by-step UX walkthrough for design evaluation. Use when designing
  interfaces, evaluating user flows, reviewing UI proposals, planning
  features, or any time you need to think through what a user will
  experience at each step.
metadata:
  type: protocol
  invocation: user-only
  practice: null
  params:
    output_path: ".scratch"
---

# UX Walkthrough

Walk through the user experience step by step. At each step, answer four questions to surface usability issues before they're built.

## Process

1. **Define the user** — who are they, what's their goal, what do they know?
2. **Identify the flow** — what sequence of steps achieves the goal?
3. **Walk each step** — answer the 4 questions at every step
4. **Surface issues** — flag where answers are "no" or uncertain
5. **Recommend** — propose fixes for each issue found

## The 4 Questions (at every step)

| # | Question | What it catches |
|---|----------|-----------------|
| 1 | **What will they SEE?** | Visibility, affordance, information hierarchy |
| 2 | **What will they THINK?** | Mental model, expectations, confusion |
| 3 | **What will they DO?** | Action they'll take (correct or incorrect) |
| 4 | **What will HAPPEN?** | System response, feedback, next state |

If the answer to any question reveals a mismatch (user thinks X but system does Y), that's a usability issue.

## Output Template

```markdown
# UX Walkthrough: [Feature/Flow Name]

## User
- **Who**: [persona or role]
- **Goal**: [what they're trying to accomplish]
- **Context**: [where they're coming from, what they know]

## Flow

### Step 1: [Name]
- **See**: [what's on screen, what's prominent]
- **Think**: [what the user expects, their mental model]
- **Do**: [action they'll take]
- **Happen**: [system response, what changes]
- **Issue**: [mismatch or friction, if any]

### Step 2: [Name]
...

## Issues Found
| # | Step | Issue | Severity | Fix |
|---|------|-------|----------|-----|

## Recommendations
[Prioritized list of changes]
```

## When to Use

- Before building: walk the proposed design on paper
- During review: evaluate an existing flow for friction
- After feedback: trace where users get stuck
- Feature planning: validate that the happy path is learnable

## Principles (from cognitive walkthrough research)

- **First-time user lens** — assume no prior training
- **Goal-driven** — users act to achieve goals, not to explore
- **Visible affordances** — if the user can't see it, it doesn't exist
- **Immediate feedback** — users need to know their action worked
- **Recovery** — errors should be reversible and clearly communicated

## Anti-Patterns

- Skipping "what will they think?" (the most revealing question)
- Assuming users read instructions (they don't)
- Designing for the expert path only
- Confusing "possible" with "discoverable"
