---
id: "28"
title: "Near-threshold judged failures triaged: agents-md, handoff-decaying, feedback-loop-tighten"
status: done
blocked_by: []
env: either
spec: "t09-baseline-followups"
---

# Near-threshold judged failures triaged: agents-md, handoff-decaying, feedback-loop-tighten

## What to build

Determine flaky-vs-genuine for the three defs that failed the 2026-07-19 baseline run near their thresholds, and apply the matching remedy per precedent (steering-pointer: trials 3→5 for flaky; ticket 13/14: content/fixture fix for genuine).

## Context (evidence from `results/2026-07-19T00-29-50Z`)

- **agents-md-authoring-effectiveness** — 3.83 vs thr 4 (was 4.16 PASS at 07-17 baseline). Delta positive both runs (1.16 → 1.0); stddev 0.89 unchanged; task 1 with-skill flat 3.0 across all 3 trials (suggests a task-1-specific ceiling or rubric mismatch, not noise).
- **handoff-decaying-resolution** — delta 0.67 vs thr 0.75 (was 5.00/1.67 PASS). CONFOUND: the 07-17 run scored this def BEFORE the a03798e handoff-skill merge landed mid-run (recorded caveat) — this is the first measurement of current content. Baseline condition rose 3.33→3.83 (delta compression). Could be content regression from a03798e or judge drift.
- **feedback-loop-tighten-effectiveness** — 3.77 vs thr 4. Oscillates: 3.88 FAIL (07-17) → 4.44 PASS ×1 (07-18, post-ticket-14 fixtures) → 3.77 FAIL. Delta healthy every run (1.33–1.89). Task 2 is the weak one (2.66 with-skill).

## Acceptance criteria

- [x] Each def re-run solo ≥2× at unchanged content; classify: flaky (variance straddles threshold) vs genuine (stable miss)
- [x] handoff-decaying: diff the a03798e handoff-skill change against the def's rubric before classifying — rule content regression in or out explicitly
- [x] Flaky defs get variance remedy (trials increase per steering-pointer precedent) or rubric/task fix; genuine ones get a content fix or `known_gap` with rationale
- [x] Baseline record 2026-07-19 amended with dispositions

## Out of scope

- Threshold/gate changes
- The 4 stable known gaps (type-error, prototype, code-review-security, cross-tool-planning)

## Resolution (2026-07-22)

Six solo re-runs at unchanged content (2× per def; kiro-only judge — codex/crush probes
failed on corp, noted as comparability caveat vs the multi-judge 07-19 run):

- **agents-md** GENUINE: FAIL 3.83/3.66, trim task flat 3 in 9 straight trials across
  both judge configs. Fix: skill trim step 2 now requires writing the extraction files.
  Post-fix verify PASS 4.33/delta 1.33, trim task [4,5,4] (2026-07-22T23-28-34Z).
- **handoff-decaying** FLAKY at delta gate (0.67/0.83/0.83 vs 0.75): trials 3→5.
  a03798e regression RULED OUT — 0/6 with-skill outputs contained the nudge section
  (skip-condition works); 07-19 delta compression traced to baseline rise, judge-set
  boundary suspected.
- **feedback-loop-tighten** FLAKY at threshold (3.88/4.44/3.77/4.44/4.33 vs 4):
  trials 3→5; leaves the known-gap set (now the 4 stable rows).

Baseline record amended (`docs/development/eval-baseline-2026-07-19.md` § Ticket 28
dispositions). Runs: results/2026-07-22T{21-57-08,22-12-03,…,23-28-34}Z.
