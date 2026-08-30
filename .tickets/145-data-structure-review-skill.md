---
id: "145"
title: "Research + propose a skill for creating and reviewing data structures (invalid-states-unrepresentable)"
status: open
blocked_by: []
priority: medium
---

# Research + propose a skill for creating and reviewing data structures (invalid-states-unrepresentable)

## Source (what triggered this)

"The Data Structure Problem AI Coding Agents Can't See" — AI That Works episode
(Boundary/HumanLayer), 2026-08-21. Local notes:
`C:\Users\uosmi\Downloads\the-data-structure-problem-ai-coding-agents-can-t-see.md`.
Only **Part 1 (data structures, Avery/Boundary)** is in scope. Part 2 (sync engines)
is a separate distributed-systems topic — NOT part of this ticket.

**Source authority: L5 (informed commentary)** — a podcast with one experiment, no
published methodology/paper. Findings are directional, not established. Before any
skill ships, corroborate the core claims against L2/L4 sources (type-theory
"make illegal states unrepresentable", published agent-code-quality studies).

## Key claims from the source (to validate, not assume)

- **Representation shapes implementation.** Right data structure → algorithms become
  obvious; wrong one → fragile control flow. (Brooks/Pike/Torvalds lineage.)
- **Make invalid states unrepresentable.** `held:bool + sold:bool` permits the illegal
  "held AND sold" state; a 3-variant enum (`Open|Held|Sold`) makes it structurally
  impossible and collapses the error handling.
- **Bad representation raises cost-of-change** — each new state multiplies call sites
  to touch; every site is a place an agent forgets → compounding bugs.
- **Measured agent failure rate ~12.5% per feature** (Codex/GPT-5.6, Ticketmaster built
  one feature at a time, 200 runs/feature). Claimed to compound to 40-50% "slop" over
  ~100 features. Likely a lower bound (simple Rust problem; expected worse in Py/TS).
- **Green tests ≠ good architecture** — every variant passed its tests while producing
  multiple sources of truth / invalid-state-prone designs. Tests don't catch this.
- **Recommended practice: review the DATA STRUCTURES, not every downstream line** —
  representation is the highest-leverage review checkpoint, especially when you won't
  read all AI-generated code.
- Agents default to the *convenient* representation (training bias); incremental
  feature-by-feature dev (no full requirements) is exactly when they go wrong. Giving
  full requirements up front largely fixes it but is infeasible for real projects.

## Research questions (dispatch subagents per source-authority gates)

1. Prior art for "make illegal states unrepresentable" as a reviewable checklist —
   type-driven design (Rust enums, TS discriminated unions, sum types, ADTs), Alexis
   King's essay, Scott Wlaschin "Domain Modeling Made Functional". [L4]
2. Existing lint/tooling that flags data-structure smells (multiple sources of truth,
   redundant flags, primitive obsession, denormalized counters that can drift). What's
   automatable vs judgment-only?
3. Is the 12.5%/feature figure corroborated anywhere else? Any published study on agent
   data-modeling quality? (If none: label the claim "single-source, unconfirmed".)
4. How does this differ across languages where illegal states are HARD to make
   unrepresentable (Python/TS/Go without sum types)? What's the review lens there?
5. Overlap check: does existing `code-review` (two-axis: Standards + Spec) already
   cover this, or is a data-structure lens a distinct axis / distinct skill?

## Proposal to produce (the deliverable of this ticket)

A written proposal (not the skill itself yet) recommending ONE of:
- **(a) A new skill** `data-structure-review` (or similarly named) covering BOTH modes
  the request names: **creation** (nudge toward invalid-states-unrepresentable at
  design time) and **review** (a lens/checklist to audit existing structures for
  invalid states, multiple sources of truth, drift-prone denormalization).
- **(b) An extension of the existing `code-review` skill** with a data-structure axis.
- **(c) A steering pointer** if the behavior is better as always-on guidance.

Decide (a)/(b)/(c) WITH the research findings, per AGENTS.md "research before
recommending". Follow skill-authoring rules (<100 lines, frontmatter, distinctive
activation triggers). Consider whether it should be gate-shaped (mandatory checklist,
"fix before presenting") since eval-proven patterns show gates > suggestions, and this
targets an unprompted-behavior gap (agents won't self-review representations).

## Acceptance criteria

- [ ] Research findings written up (sources cited with authority levels; the 12.5% claim explicitly labeled by confidence)
- [ ] Overlap analysis vs existing code-review skill documented (distinct skill vs extension vs steering)
- [ ] Recommendation (a/b/c) with rationale grounded in findings + eval-proven skill patterns
- [ ] If a skill is recommended: a draft SKILL.md sketch (frontmatter + creation-mode + review-mode sections) and target tier
- [ ] Decision on whether the behavior is measurable → an eval definition proposed
