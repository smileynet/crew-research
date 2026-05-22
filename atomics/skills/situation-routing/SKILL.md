---
name: situation-routing
description: >
  Decision framework for routing work to the right agent or approach based
  on situation signals. Use when deciding who should handle a task, which
  crew to delegate to, or which reasoning mode to apply.
metadata:
  type: decision
  invocation: both
  practice: autonomy-delegation
---

# Situation Routing

Select the right handler based on observable signals, not guesses.

## Selection Criteria

| Signal | Route To | Rationale |
|--------|----------|-----------|
| User expresses uncertainty ("not sure how") | Research first | Novel domain needs investigation before action |
| Well-understood task, clear requirements | Direct execution | No research overhead needed |
| Multiple valid approaches, need to choose | Decision analysis | Weigh tradeoffs before committing |
| Something broke, need to understand why | Diagnosis (five-whys, diagnose) | Root cause before fix |
| Plan exists, need to stress-test it | Pre-mortem / red-team | Challenge before committing |
| Task too large for one agent | Decompose + delegate | Split by independence |
| Task requires tools agent doesn't have | Escalate or hand off | Don't attempt without capability |

## Decision Process

1. **Observe** — what signals are present in the request?
2. **Match** — which row in the table fits?
3. **Verify** — does the match make sense? (sanity check)
4. **Route** — delegate with full context (what, why, constraints)

## When to Switch

- If you routed to research but the answer is obvious → switch to direct execution
- If you routed to execution but hit unknowns → switch to research
- If 3+ decisions made without user input → pause and surface assumptions

## Anti-Patterns

- Routing to research for well-known tools (eslint, git, standard libraries)
- Routing to execution when user expressed uncertainty
- Self-executing when you lack the required tools
- Delegating without passing full context (what to do, what NOT to do)
