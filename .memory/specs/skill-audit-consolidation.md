---
type: specification
title: "Skill Audit — Baseline, Consolidate, Prune"
---

# Spec: Skill Audit — Baseline, Consolidate, Prune

**Status:** Ready
**Date:** 2026-07-06

---

## Objective

Audit all 64 skills against three questions:
1. **Does it perform above baseline?** (eval delta > 0)
2. **Is it a legitimate standalone entry point?** (user prompt or distinct agent knowledge)
3. **Should it be consolidated?** (overlap with another skill, could be a reference/ file instead)

Output: a smaller, higher-signal skill set where every skill either activates reliably with measurable impact OR provides a distinct user workflow.

---

## Current Inventory

| Category | Count | Examples |
|----------|-------|---------|
| User-only prompts | 15 | handoff, grill-with-docs, project-cleanup |
| Agent-only (steering) | 4 | recall-check, recall-session-start, project-conventions, research-dispatch |
| Passive (steering) | 2 | context-budget-awareness, source-authority |
| Dual-mode (both) | 43 | planning-cycles, code-review, testing-guide |

64 total. 14 in basic tier, 52 in full tier, 14 not in any tier (project-level or plugin).

---

## Phase 1: Baseline All Skills

Run the activation suite + a representative effectiveness eval for each skill cluster. We don't need per-skill evals for all 64 — cluster them and test representatives.

### Activation baseline (already have data for 34 skills)

Missing activation tests for: `adopt-project`, `cheatsheet`, `context-budget-awareness`, `feedback-loop-debugging`, `grill-with-docs`, `image-analysis`, `init-project`, `plan-prereqs`, `poc-workflow`, `project-audit`, `project-cleanup`, `project-conventions`, `project-winddown`, `prompt-vocabulary`, `prototype-protocol`, `recall-check`, `recall-session-start`, `research-dispatch`, `research-topics`, `source-authority`, `spec-driven-development`, `study-all-references`, `study-reference`, `ux-walkthrough`, `vertical-slice-planning`.

Many of these are user-only (activation test is meaningless — user invokes explicitly). Focus activation testing on `both` invocation skills only.

### Effectiveness baseline (need new evals for uncovered clusters)

| Cluster | Representative | Has eval? | Expected delta |
|---------|---------------|-----------|---------------|
| Planning | planning-cycles | ✅ (retired, Δ=0) | Low — model plans well already |
| Research | research-methodology | ❌ | Medium — structured output format adds value |
| Writing | writing-style | ✅ (activation only) | Low — model writes well |
| Debugging | five-whys | ✅ (retired, Δ=0) | Low — model does RCA unprompted |
| Project lifecycle | init-project | ❌ | N/A — mechanical (creates files) |
| Code quality | code-review | ✅ (activation only) | Low — model reviews well |
| Verification | verification-protocol | ✅ (retired, Δ=0) | Low — model caught up |
| Specs | spec-driven-development | ✅ | Unknown |
| Recall | recall | ✅ (cross-session) | High with steering |

**Key insight:** Most skill clusters show Δ≈0 on single-turn evals because models already do these things when asked directly. The value is in **unprompted behavior** (skills that make the agent do something it wouldn't otherwise) and **structured workflows** (skills that provide a specific process for complex multi-step tasks).

---

## Phase 2: Classification

Classify each skill into one of:

| Classification | Criteria | Action |
|---------------|----------|--------|
| **Keep (standalone)** | Distinct user entry point OR measurable agent behavior change | No change |
| **Keep (reference)** | Valuable knowledge but should be lazy-loaded from another skill | Move to `references/` of parent skill |
| **Consolidate** | Overlaps significantly with another skill | Merge content, redirect |
| **Promote to steering** | Always-on behavior that never activates as a skill | Move to eager-context |
| **Remove** | No measurable delta, no unique user entry point, duplicates model capability | Delete |

### Preliminary classification (based on inventory analysis)

#### Likely KEEP (standalone) — 28 skills

User-invoked workflows (irreplaceable entry points):
- `handoff`, `read-handoff` — session continuity pair
- `grill-with-docs` — design interrogation (complex multi-step)
- `project-cleanup`, `project-audit`, `project-winddown` — lifecycle management
- `init-project`, `adopt-project` — scaffolding
- `cheatsheet` — meta-reference
- `plan-prereqs` — pre-work identification
- `study-reference`, `study-all-references` — reference repo analysis
- `research-topics` — parallel dispatch

Agent knowledge (distinct domains):
- `planning-cycles` — phased planning protocol
- `spec-driven-development` — PLAN.md + spec workflow
- `vertical-slice-planning` — milestone methodology routing
- `code-review` — review standards
- `testing-guide` — testing patterns
- `deployment-safety` — production change gates
- `git-protocol` — commit/push workflow
- `recall` — cross-session memory
- `diagrams` — visualization (Mermaid, ASCII, C4)
- `architecture-deepening` — refactoring analysis
- `skill-authoring` — meta (authoring new skills)
- `fiction-craft`, `world-building` — creative (project-level)
- `poc-workflow`, `prototype-protocol` — exploratory (project-level)

#### Likely CONSOLIDATE — 18 skills

**Research cluster → merge into `research-methodology`:**
- `research-output` → becomes `research-methodology/references/output-format.md`
- `research-dispatch` → becomes `research-methodology/references/dispatch-pattern.md`
- `reference-exploration` → merge into `study-reference` (same purpose, different name)

**Writing cluster → merge into `writing-style`:**
- `changelog-discipline` → becomes `writing-style/references/changelog.md`
- `document-formats` → becomes `writing-style/references/formats.md`
- `diataxis-classification` → becomes `docs-audit/references/diataxis.md` (or `writing-style`)

**Debugging cluster → merge into `troubleshooting-protocol`:**
- `five-whys` → becomes `troubleshooting-protocol/references/five-whys.md`
- `feedback-loop-debugging` → merge into `troubleshooting-protocol` (same trigger, same domain)

**Planning cluster:**
- `assumption-tracking` → becomes `planning-cycles/references/assumptions.md`
- `prompt-vocabulary` → becomes `planning-cycles/references/reasoning-modes.md`

**Project lifecycle:**
- `completion-protocol` → merge into `git-protocol` (it's really "commit + verify + signal done")

**Docs cluster:**
- `agents-md-authoring` → becomes `skill-authoring/references/agents-md.md` (meta skill)
- `docs-audit` absorbs `diataxis-classification`

**Code quality:**
- `commit-pr-discipline` → becomes `git-protocol/references/commit-messages.md`

**Specs:**
- `spec-review` → becomes `spec-driven-development/references/review-checklist.md`

#### Likely PROMOTE TO STEERING — 4 skills (already done)

Already deployed as steering: `context-budget-awareness`, `source-authority`, `recall-check`, `recall-session-start`. These are correctly positioned.

Also consider:
- `verification-protocol` — already steering + skill; the skill adds nothing over the steering (Δ=0 in eval). Remove the skill, keep steering only.

#### Likely REMOVE — 4 skills

- `image-analysis` — trivially accomplished by the model without any instruction. The "skill" is just "read the image and describe it." No protocol, no value-add.
- `situation-routing` — retired eval showed Δ=0. The decision framework it provides is what models do naturally when asked "which approach should I take?"
- `session-review-patterns` — meta skill for reviewing session transcripts. Narrow audience (us). Could be a reference file in `eval-criteria`.
- `ux-walkthrough` — never tested, narrow applicability, could be a reference file in `code-review`.

---

## Phase 3: Execute Consolidation

For each merge:
1. Move content to `references/` of the parent skill
2. Add a lazy-loading pointer in the parent SKILL.md ("For X, read references/Y.md")
3. Update tier manifests to remove the consolidated skill
4. Update cross-links and cheatsheet
5. Run `mise run validate` to catch broken references

### Execution order (minimize disruption)

1. **Trivial removals** — `image-analysis`, `situation-routing`
2. **Clear merges** — research-output→research-methodology, five-whys→troubleshooting
3. **Cluster merges** — writing cluster, debugging cluster
4. **Complex merges** — completion-protocol→git-protocol, spec-review→spec-driven-development

---

## Phase 4: Re-baseline

After consolidation:
1. Run activation suite on remaining skills
2. Run `mise run validate` (compositions + cross-links)
3. Update `mise run catalog` output
4. Run `mise run doctor` on a fresh workspace
5. Verify the cheatsheet still lists everything available

---

## Success Criteria

| Metric | Before | Target |
|--------|--------|--------|
| Total skills | 64 | ≤45 |
| Skills in basic tier | 14 | ≤12 |
| Skills in full tier | 52 | ≤38 |
| Skills with zero delta + no unique entry point | ~10 | 0 |
| Average SKILL.md size | 74 lines | <80 lines (consolidation adds references/) |
| `mise run validate` | PASS | PASS |

---

## Risks

| Risk | Mitigation |
|------|-----------|
| Removing a skill that users rely on | Classification is conservative; "remove" only for clearly redundant skills |
| Consolidation makes parent skill too large | Use progressive disclosure — parent stays <100 lines, detail in references/ |
| Activation regression after renaming | Run activation tests before/after |
| Merge conflicts if multiple skills share a reference | One parent per reference file; use symlinks or duplicate if truly shared |

---

## Non-Goals

- Rewriting skill content (only restructuring)
- Creating new skills (only merging/removing)
- Changing steering behavior (only classifying which skills should BE steering)
- Running full eval suite (targeted testing only for borderline cases)
