---
title: "Session Eval Results: Steering Pointer + Skill Authoring"
date: 2026-06-14
status: complete
---

# Session Eval Results (2026-06-14)

## Steering Pointer Effectiveness ✅ NEW MECHANISM

**Question:** Does a steering pointer reliably cause the agent to read a manual-inclusion detail file and incorporate its content?

**Result:** PASS — delta +1.34 (with-pointer 4.50 vs baseline 3.16)

| Task | With Pointer | Baseline | Delta |
|------|-------------|----------|-------|
| Grill session (should activate) | 4.0 (4/4/4) | 1.33 (1/2/1) | +2.67 |
| Unrelated task (should ignore) | 5.0 (5/5/5) | 5.0 (5/5/5) | 0.0 |

**Key findings:**
- Pointer reliably activates — consistent scores, zero false activation
- Low variance with pointer (0.5) vs high variance baseline (1.86)
- No context bleed — unrelated tasks unaffected by the pointer's presence
- Mechanism validated: ADR 0002 third tier works as designed

**Harness enhancement:** Added `steering:` array per condition in eval definitions. Files sourced from `tools/evals/steering/`, deployed to `$workdir/.kiro/steering/`.

---

## Skill Authoring Effectiveness ✅ HARDENED

**Question:** Does the skill-authoring skill produce better-structured skills with stronger triggers?

**First run (pre-hardening):** FAIL — delta 0.50 (with 4.5 vs baseline 4.0)
- Task 0 (create): +1.33 delta — skill helped
- Task 1 (critique): -0.34 delta — baseline already perfect at critique

**Diagnosis:** Model is naturally good at critique when asked explicitly. Creation is where it fails unprompted (inconsistent format, missing scope declarations, generic triggers).

**Fix:** Added Creation Gates (G1-G5) — mandatory checklist before presenting a new skill as complete:
- G1: Description has "Use when" + 3 trigger keywords
- G2: Body is steps/process
- G3: Scope boundary declared
- G4: Under 100 lines
- G5: Single concern

**Second run (post-hardening):** PASS — delta +1.34 (with 5.0 vs baseline 3.66)

| Task | With Skill | Baseline | Delta |
|------|-----------|----------|-------|
| Write new skill | 5.0 (5/5/5) | 3.0 (1/4/4) | +2.0 |
| Critique existing | 5.0 (5/5/5) | 4.33 (5/4/4) | +0.67 |

**Key findings:**
- Gates eliminate variance entirely (stddev 0 with skill)
- Baseline still has floor drops (scored 1 on creation without skill)
- Gates improved BOTH tasks — critique now references G1-G5 explicitly
- Pattern confirmed: explicit gates > permissive guidance for enforcing unprompted behavior

---

## Context-Neutrality Dispatch ❌ HYPOTHESIS DISPROVEN

**Question:** Does dispatching evaluation tasks to a subagent with fresh context produce better self-critique than inline review?

**Hypothesis:** The agent anchors on its own creation reasoning, so a fresh-context subagent should produce more objective evaluation.

**Run 1 (vague dispatch steering):** Delta +0.17, massive variance (1-5 on both conditions). Agent didn't know *how* to dispatch correctly — subagent can't read workspace files.

**Run 2 (explicit mechanism — read back code, paste into subagent prompt):** Delta +0.16 (dispatch 4.66 vs inline 4.50). Both conditions scored 4-5.

| Task | With Dispatch | Inline | Delta |
|------|-------------|--------|-------|
| Review own impl | 4.33 (5/3/5) | 4.0 (4/4/4) | +0.33 |
| Audit own impl | 5.0 (5/5/5) | 5.0 (5/5/5) | 0.0 |

**Why it failed:**
- The model is already good at self-critique when explicitly prompted to be critical ("what would break?", "what would a hostile reviewer find?")
- Fresh context doesn't add meaningful objectivity over good critical framing
- The dispatch mechanism adds latency and complexity for no quality gain
- Subagent tool limitations (no file access, no grep/glob) make it harder, not easier

**Conclusion:** The value isn't in *where* the review happens (fresh vs inline context). It's in *how it's prompted* (explicit critical framing). Critical prompts in review steps beat dispatch mechanics.

**Action:** Drop "update 9 skills for subagent dispatch" from the queue. Instead, ensure review-oriented skills include strong critical-framing instructions in their review steps (most already do).

---

## Meta-Insights

1. **Gates > suggestions.** Mandatory checklists with "fix before presenting" produce consistent behavior. Optional advice doesn't.
2. **Don't eval what the model already does well.** Critique tasks show no delta because the model is already good when explicitly asked. Target skills at what it WON'T do unprompted.
3. **Steering pointers work.** The mechanism is reliable, context-efficient, and doesn't bleed. Ready for user-facing documentation.
4. **Variance is the enemy.** Both evals show the same pattern: skills reduce variance more than they raise average. A skill that makes a 1→4 floor is more valuable than one that makes a 4→5 ceiling.
5. **Critical framing > dispatch mechanics.** Self-review quality depends on prompt framing ("find issues", "what would break"), not execution context. Don't add mechanism complexity when better prompting solves it.
