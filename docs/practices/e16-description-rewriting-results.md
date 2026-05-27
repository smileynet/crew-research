---
title: "E16: Description Rewriting vs Eager Loading"
date: 2026-05-27
status: complete
skills: [diagrams, ai-generation-hygiene, verification-protocol]
---

# E16: Description Rewriting vs Eager Loading

## Summary

Description rewriting **fully fixes** diagrams (0% → 100%) but **cannot fix** verification-protocol (40% → 0%). ai-generation-hygiene improves (20% → 60%) but remains unreliable. Recommendation: eager-load verification-protocol and ai-generation-hygiene; keep diagrams as lazy-loaded with improved description.

## Results

| Skill | E7 (original) | E16 (rewritten) | Delta | Recommendation |
|-------|:-:|:-:|:-:|---|
| diagrams | 0% | **100%** | +100% | ✅ Keep as skill (fixed) |
| ai-generation-hygiene | 20% | **60%** | +40% | ⚠️ Eager-load (still unreliable) |
| verification-protocol | 40% | **0%** | -40% | ❌ Eager-load (unfixable via description) |

## Analysis

### diagrams: Fixed by description rewriting

**Before**: "Architecture diagrams for documentation. Covers ASCII, Mermaid, C4, and D2."
**After**: Added "visualize, draw, illustrate, map out, show how components connect, show the architecture, explain visually"

The original description was too narrow — it only matched explicit "diagram" requests. Adding visual/spatial verbs gave kiro-cli enough trigger surface. This is a pure vocabulary problem.

### ai-generation-hygiene: Improved but fundamentally limited

**Before**: "Eliminate common AI-generation artifacts from produced code."
**After**: Added "writing code, generating functions, implementing features, creating scripts, producing any code output"

Improved from 1/5 to 3/5. Still fails on "Write a TypeScript utility module" and "Implement a caching layer" — tasks where the user's intent is the feature, not code quality. The skill is meant to apply **during** all code generation, but description matching can only trigger on what the user **asks for**.

**This is the activation bottleneck in its purest form**: broad-applicability skills can't reliably activate because the user's query is about the task, not the meta-concern.

### verification-protocol: Unfixable via description

**Before**: "Verification steps before reporting work is done. Use when finishing a task, fixing a bug..."
**After**: Added "implement, fix, change, complete, done, verify, validate, confirm it works"

Got WORSE (40% → 0%). Adding implementation-related triggers may have confused the matcher — now it competes with every other skill that handles implementation tasks. The fundamental problem: verification is a **post-task** concern. Users say "fix the bug" not "verify after fixing the bug."

## Conclusion

Description rewriting works when:
- The skill has distinctive domain vocabulary that was simply missing from the description
- The skill IS the primary task (diagrams, research, planning)

Description rewriting fails when:
- The skill is a meta-concern that applies DURING other work
- The user's query is about the task, not the quality/verification layer

## Recommendation

1. **diagrams** — keep as lazy-loaded skill with new description. Fixed. ✅
2. **ai-generation-hygiene** — eager-load as steering. Can't reliably activate on generic code tasks.
3. **verification-protocol** — eager-load as steering. Fundamentally a post-task concern that can't match on task descriptions.

This aligns with agent-crews' prior art: they put ai-generation-hygiene as steering (`inclusion: always`).

## Data

- `tools/evals/results/activation-2026-05-27T22-05-25Z/` (diagrams: 100%)
- `tools/evals/results/activation-2026-05-27T22-08-09Z/` (ai-gen-hygiene: 60%)
- `tools/evals/results/activation-2026-05-27T22-12-11Z/` (verification: 0%)
