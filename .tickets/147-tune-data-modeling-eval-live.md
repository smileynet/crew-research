---
id: "147"
title: "Tune data-modeling skill via eval against live/existing projects"
status: in_progress
blocked_by: ["146"]
---

# Tune data-modeling skill via eval against live/existing projects

Follow-on to 145 (research) + 146 (implementation). Blocked by 146 (need the skill to exist).
Purpose: don't ship on synthetic fixtures alone — validate and TUNE the data-modeling skill
against REAL data structures from live/existing projects, then adjust the skill from what fails.

## Why live projects (not just synthetic)

The 145 research eval sketch uses a synthetic Order/boolean-flags fixture. That proves the
mechanism but not real-world calibration: the skill could over-fire on legitimately-simple structs
or miss domain-specific invalid states. Tuning against real repos surfaces false-positive and
false-negative rates that a hand-made fixture can't.

## What to build

1. **Build the eval defs** (from 145's sketch):
   - `tools/evals/definitions/data-modeling-illegal-states-effectiveness.yaml` — dual-run,
     two tasks: (1) Order boolean flags → reward sum-type refactor making illegal combos
     unrepresentable; (2) independent feature flags → PUNISH over-application (the over-firing
     guard). Binary checklist criteria, threshold 3.0, delta_threshold -0.5.
   - `tools/evals/definitions/activation-data-modeling.yaml` — 5 pos / 5 neg, gates TPR>=0.5, FPR<=0.2.

2. **Assemble a live-project corpus** — pull REAL data structures from existing projects on this
   machine (candidates: the game-research, shadowrun-sega, recall, tkt repos; recall wings list real
   projects). Extract 5-10 real type/struct/schema definitions spanning languages (Rust enums, TS
   interfaces, Python dataclasses, Go structs) — some well-modeled (should PASS review), some
   invalid-state-prone (should get findings). This is the FP/FN calibration set.

3. **Run the skill's review mode over the corpus** — score: does it flag the genuinely-bad ones
   (recall/TPR) without flagging the genuinely-fine ones (precision/FPR)? Record per-item verdicts.

4. **Tune the skill from failures** — adjust SKILL.md / review-checklist.md thresholds and wording
   based on FP/FN patterns (e.g. if it flags every 2-field struct, tighten the "primitive obsession"
   / "mutually-exclusive" criteria). Iterate until activation gates pass AND the live-corpus
   FP rate is acceptable. Feed any wording changes back to ticket 146's skill files.

5. **Record results** — `docs/development/` results note + eval scores; update the skill's own
   known-limitations if the live corpus reveals a language/domain it handles poorly.

## Notes

- Run evals per eval-execution steering (background, setsid, observe with sleep cycles — NEVER inline).
- Live corpus files are READ-ONLY inputs; extract copies into a fixture dir, never mutate source repos.
- Over-application (task 2) is the load-bearing negative case — the 145 fork analysis flagged
  over-firing as the main risk; the live corpus is how we measure it for real.

## Acceptance criteria

- [ ] Both eval defs created and runnable (dual-run + activation)
- [ ] Live-project corpus assembled (5-10 real structures, multi-language, mix of good/bad)
- [ ] Review mode scored over the corpus with per-item TPR/precision recorded
- [ ] Skill tuned from FP/FN findings; changes fed back to 146's skill files
- [ ] Activation gates pass (TPR>=0.5, FPR<=0.2) AND live-corpus false-positive rate documented as acceptable
- [ ] Results recorded in docs/development/
