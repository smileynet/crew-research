---
title: "E7: Activation Sweep Results"
date: 2026-05-27
status: complete
skills: []
---

# E7: Activation Sweep Results

## Summary

Tested all 33 agent-loadable skills for activation reliability. Overall: **81% recall, 4% FPR, 88% accuracy** across 330 tasks (10 per skill).

## Method

- 5 relevant tasks + 5 irrelevant tasks per skill
- Single-trial activation check via `run-activation.sh --all`
- Threshold: 4/5 relevant tasks must activate for a skill to "pass"

## Results by Tier

| Tier | Activation Rate | Skills |
|------|:-:|------|
| 🟢 Perfect | 100% | adr-authoring, deployment-safety, diataxis-classification, enforcement-hierarchy, eval-criteria, git-protocol, handoff, presentation-writing, readme-writing, script-authoring, session-review-patterns, situation-routing, testing-guide, troubleshooting-protocol, tutorial-authoring, world-building |
| 🟡 Good | 80% | assumption-tracking, changelog-discipline, docs-audit, document-formats, fiction-craft, five-whys, planning-cycles, research-methodology, research-output, writing-style |
| 🟠 Weak | 60% | code-review, commit-pr-discipline, completion-protocol, reference-exploration |
| 🔴 Failing | ≤40% | verification-protocol (40%), ai-generation-hygiene (20%), diagrams (0%) |

## False Positives (7 total, 4% rate)

| Skill | False Trigger |
|-------|--------------|
| code-review | "Write a migration script..." |
| completion-protocol | "What design patterns...", "List all environment variables..." |
| eval-criteria | "Add pagination..." |
| testing-guide | "Set up a Redis cluster..." |
| world-building | "Create database seeds..." |
| writing-style | "Explain how consistent hashing works" |

## Analysis: Why Skills Fail to Activate

### Pattern: Broad-applicability skills lack distinctive triggers

The 3 failing skills share a trait: they're meant to apply **during** other work, not as the primary task:

- **diagrams** — you don't usually ask "make a diagram" in isolation; you ask "explain the architecture" and a diagram is one output format
- **ai-generation-hygiene** — applies during ALL code generation, but "write a function" doesn't trigger it because the description says "AI-generation artifacts"
- **verification-protocol** — applies when completing ANY task, but "fix the bug" doesn't trigger it because the description says "task completion sequence"

### Pattern: Distinctive vocabulary = reliable activation

Skills at 100% all have domain-specific trigger words that don't overlap with generic coding:
- "ADR", "architectural decision" → adr-authoring
- "deploy", "canary", "rollback" → deployment-safety
- "session transcript", "protocol compliance" → session-review-patterns
- "magic system", "fictional world" → world-building

### The activation bottleneck is a description problem, not a content problem

These skills work perfectly when loaded. The issue is that kiro-cli's semantic matching can't infer "this code generation task should also load hygiene rules" from a description that says "eliminate AI-generation artifacts."

## Hypothesis: Cross-Skill Linking as Activation Strategy

Instead of relying on direct activation, failing skills could be **invoked by other skills** that DO activate reliably:

- `script-authoring` (100% activation) could reference `ai-generation-hygiene` as a companion
- `completion-protocol` could be referenced by `git-protocol` (100%) at the "mark done" step
- `diagrams` could be referenced by `planning-cycles` (80%) or `readme-writing` (100%)

This treats failing skills as **workflow participants** rather than standalone entry points.

## Recommendations

1. **Cross-skill linking** — test whether referencing a skill from another skill's content triggers progressive loading
2. **Eager-load candidates** — if linking doesn't work, move the 3 failing skills to steering (always-on)
3. **Description rewriting** — as a simpler alternative, rewrite descriptions with more distinctive trigger vocabulary
4. **No action needed** for 80%+ skills — they activate reliably enough for practical use

## Data

Results: `tools/evals/results/activation-2026-05-27T06-07-54Z/`
Definitions: `tools/evals/definitions/activation-*.yaml` (33 files)
