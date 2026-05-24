---
metadata:
  type: reference
  invocation: both
  practice: null
name: enforcement-hierarchy
description: Select the right enforcement mechanism for agent behavior rules. Use when configuring agent constraints, writing AGENTS.md, designing skills, or deciding how to enforce a new rule.
---
metadata:
  type: reference
  invocation: both
  practice: null

# Enforcement Hierarchy

Source of truth: `/home/sam/code/best_practices/docs/practices/enforcement-hierarchy.md`

Never rely on a weaker mechanism when a stronger one is available.

## Trigger Conditions

Activate when:
- Configuring agent permissions or constraints
- Writing AGENTS.md rules or steering files
- Deciding how to enforce a new convention
- Reviewing whether existing rules are enforced at the right level
- Designing CI/CD pipelines or pre-commit hooks

## The Four Levels

```
Level 1: Tool Permissions       → physically impossible to violate
Level 2: Automated Validation   → caught automatically after the fact
Level 3: Verification Gate      → independent judgment before completion
Level 4: Steering Guidance      → shapes behavior, can be overridden
```

## Selection Rules

**Catastrophic consequence (data loss, security breach, irreversible action):**
→ Level 1. Use deniedCommands, deniedPaths, or don't grant the tool.

**Clear programmatic definition (formatting, types, structure, naming):**
→ Level 2. Use linters, type checkers, schema validators, pre-commit hooks.

**Requires judgment to evaluate (correctness, completeness, quality, design):**
→ Level 3. Use verifier agents, review commands, test suites, human review.

**Preference or soft convention (style, approach, tone):**
→ Level 4. Use steering files, AGENTS.md, skills, comments.

## Required Patterns

**Promote critical rules.** MUST NOT rely on Level 4 (steering) for rules where violation has serious consequences. If an agent should never push to main, use deniedCommands — not a prose instruction.

**Match mechanism to rule type.** MUST choose the strongest mechanism that fits the rule's nature. Mechanical rules get automation; judgment rules get verification; preferences get guidance.

**Layer mechanisms.** SHOULD use multiple levels for important rules. A rule can have Level 2 (lint catches obvious cases) AND Level 3 (reviewer catches subtle cases). Layers are additive.

## Banned Patterns

**Steering for critical rules.** MUST NOT write "NEVER do X" in AGENTS.md when deniedCommands or deniedPaths can physically prevent X.

**All rules at Level 4.** MUST NOT put every rule in prose guidance. The agent's attention is finite — burying critical rules among preferences dilutes enforcement.

**Automation for judgment calls.** SHOULD NOT create lint rules for subjective style preferences. False positives from overly strict automation create friction without value.

## Quick Reference

| I want to prevent... | Use |
|---------------------|-----|
| Deleting production data | Level 1: deniedCommands |
| Modifying agent config | Level 1: deniedPaths |
| Shipping type errors | Level 2: CI type-check |
| Shipping broken tests | Level 2: CI test runner |
| Shipping incorrect logic | Level 3: verifier agent |
| Shipping bad prose | Level 3: editor agent |
| Using verbose variable names | Level 4: style skill |
| Preferring composition | Level 4: AGENTS.md |

## References

- Source practice: [`docs/practices/enforcement-hierarchy.md`](../../../docs/practices/enforcement-hierarchy.md)
- Origin: `agent-crews/shared/steering/reliability.md`
