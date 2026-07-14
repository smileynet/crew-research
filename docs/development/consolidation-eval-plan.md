---
type: specification
title: "Consolidation Impact Eval Plan"
---

# Consolidation Impact Eval Plan

**Purpose:** Measure whether merged skills retain their effectiveness when accessed as `references/` files within a parent skill, compared to when they existed as standalone skills.

**Date:** 2026-07-11

---

## Design

### Question

> When we consolidate skill X into parent Y's `references/` directory, does the agent still produce the same quality output on tasks that skill X was designed for?

### Method: Dual-Run Regression Comparison

Each eval compares two conditions using the same tasks/criteria:

| Condition | What's deployed | Represents |
|-----------|----------------|-----------|
| **with-skill** (primary) | Parent skill + references/ | Post-consolidation state |
| **baseline** | Original standalone skill | Pre-consolidation state |

**Delta = parent score - standalone score**

### Pass Criteria

| Criterion | Threshold | Meaning |
|-----------|-----------|---------|
| Parent absolute score | ≥ 3.5 | Content accessible via progressive loading still produces acceptable quality |
| Regression delta | ≥ -0.5 | Minor drop acceptable (progressive loading overhead), but no major regression |

A negative delta of 0.5 is acceptable because:
- Progressive loading adds one indirection hop (SKILL.md → references/file.md)
- The parent skill's own content may compete for attention with the referenced content
- Agent may not always navigate to the reference file on the first attempt

A delta of -1.0+ signals real breakage — the content is effectively lost or inaccessible.

### Harness Modification

Patched `tools/evals/harness/run.sh` to deploy `references/` directory alongside SKILL.md. Previously the harness only copied the primary file; real deployment (init.sh) always copies both.

---

## Eval Definitions

### 1. consolidation-five-whys.yaml

| Property | Value |
|----------|-------|
| Parent skill | troubleshooting-protocol |
| Standalone skill | five-whys |
| Target behavior | Causal chain reasoning (iterative root cause analysis) |
| Tasks | Recurring API outage RCA, user confusion diagnosis |
| Risk | five-whys is a reasoning MODE — may not be triggered by troubleshooting-protocol's description |

### 2. consolidation-prompt-vocabulary.yaml

| Property | Value |
|----------|-------|
| Parent skill | planning-cycles |
| Standalone skill | prompt-vocabulary |
| Target behavior | Named technique recommendation with selection criteria |
| Tasks | Migration risk analysis approach, conflicting thinking mode sequencing |
| Risk | planning-cycles is a PROTOCOL — may focus on phases rather than technique selection |

### 3. consolidation-feedback-loop.yaml

| Property | Value |
|----------|-------|
| Parent skill | troubleshooting-protocol |
| Standalone skill | feedback-loop-debugging |
| Target behavior | Build feedback loop (reproduce failure) BEFORE fixing |
| Tasks | Failing test diagnosis, TypeError reproduction |
| Risk | troubleshooting-protocol's Phase 1 (investigate) covers this but less explicitly |

### 4. consolidation-spec-review.yaml

| Property | Value |
|----------|-------|
| Parent skill | spec-driven-development |
| Standalone skill | spec-review |
| Target behavior | BLOCK vague/untestable specs instead of approving with suggestions |
| Tasks | Vague requirements detection, untestable validation detection |
| Risk | spec-driven-development focuses on writing specs, not reviewing them |

---

## Expected Outcomes

### Best case (all PASS)
Parent skills with references/ produce equivalent quality → consolidation is safe, proceed with all 18 merges.

### Mixed results
Some parent skills regress on specific behaviors → those specific merges need:
- Stronger pointer in parent SKILL.md (explicit "For X, read references/Y.md")
- Or inline summary in parent (1-2 lines capturing the key behavior)
- Or keep as standalone (consolidation not viable for this skill)

### Worst case (all FAIL with delta < -1.0)
Progressive loading fundamentally doesn't work for these behavior types → reconsider the consolidation strategy. The content may need to stay in standalone skills that activate independently.

---

## Workflow

```
1. Run baseline evals (pre-consolidation, current state)
   → Both conditions use standalone skills in their current form
   → Captures: "How good is troubleshooting-protocol at five-whys tasks TODAY?"

2. Execute consolidation (Phase 3 of skill-audit-consolidation.md)
   → Move skill content to references/ of parent skills
   → Add progressive loading pointers in parent SKILL.md

3. Re-run same evals (post-consolidation)
   → "with-skill" condition now tests the MERGED parent
   → "baseline" condition tests the now-deleted standalone skill
   → Delta reveals regression from the merge

4. Iterate on failures
   → Strengthen pointers, add inline summaries, revert if needed
```

---

## Coverage Assessment

| Merge category | Representative eval | Remaining untested |
|---------------|--------------------|--------------------|
| Reasoning mode → protocol reference | consolidation-five-whys | — |
| Decision skill → protocol reference | consolidation-prompt-vocabulary | assumption-tracking |
| Debugging method → protocol reference | consolidation-feedback-loop | — |
| Review checklist → development reference | consolidation-spec-review | agents-md-authoring → skill-authoring |
| Writing sub-skill → style reference | NONE | changelog, document-formats, diataxis |
| Git sub-skill → protocol reference | NONE | completion-protocol, commit-pr-discipline |

The 4 evals cover the highest-risk merges (skills with proven effectiveness baselines). The writing and git clusters are lower risk — those skills had only activation evals, suggesting marginal standalone value.

---

## Baseline Results (Pre-Consolidation, 1-Trial)

Run: 2026-07-11, using current standalone skills vs their intended parent skills.

| Eval | Parent Score | Standalone Score | Delta | Status |
|------|:-----------:|:---------------:|:-----:|:------:|
| consolidation-prompt-vocabulary | 4.83 | 4.83 | 0.00 | ✅ PASS |
| consolidation-five-whys | 3.66 | 4.00 | -0.34 | ✅ PASS |
| consolidation-feedback-loop | 1.66 | 2.50 | -0.84 | ❌ FAIL |
| consolidation-spec-review | 5.00 | 4.83 | +0.17 | ✅ PASS |

### Interpretation

**3/4 PASS** — consolidation is broadly safe for the tested skill pairs.

**Prompt-vocabulary → planning-cycles:** Perfect parity. Planning-cycles already covers reasoning technique selection through its "Spike vs Tracer Bullet vs Prototype" section and decision tree. The content naturally fits.

**Five-whys → troubleshooting-protocol:** Minor regression (-0.34). The parent skill's "Phase 1: Investigate" and "Phase 2: Hypothesis" cover root cause analysis but don't explicitly encode the iterative why-chain format. Acceptable — the behavior is present, just less structured.

**Feedback-loop → troubleshooting-protocol:** FAIL. Two problems:
1. **Absolute quality:** Even the standalone skill only scores 2.5 (below the 4.0 effectiveness threshold). The behavior (reproduce before fix) is hard to elicit regardless of skill.
2. **Regression:** Parent skill scores 1.66 — doesn't trigger feedback-loop behavior at all. The troubleshooting-protocol's description doesn't activate on "fix this test" prompts (0.16 activation rate).

**Recommendation for feedback-loop:** Keep as standalone skill OR significantly strengthen the troubleshooting-protocol to explicitly mention "reproduce first" in its primary SKILL.md body (not just references/).

**Spec-review → spec-driven-development:** Parent actually OUTPERFORMS standalone (+0.17). The broader development context (spec-driven-development covers the full spec lifecycle) helps the agent be more rigorous in review. This is the ideal outcome.

### Decision Matrix

| Merge | Safe to proceed? | Condition |
|-------|:----------------:|-----------|
| prompt-vocabulary → planning-cycles | ✅ Yes | No regression |
| five-whys → troubleshooting-protocol | ✅ Yes | Add explicit "five-whys" pointer in parent |
| feedback-loop → troubleshooting-protocol | ❌ No | Keep standalone; investigate further |
| spec-review → spec-driven-development | ✅ Yes | Parent is better than standalone |

---

## Non-Goals

- Testing all 18 consolidation targets individually (4 representative samples suffice)
- Establishing that parent skills are BETTER than standalone (only testing non-regression)
- Multi-trial statistical significance (1-trial run is acceptable for go/no-go signal; 3-trial confirms)
