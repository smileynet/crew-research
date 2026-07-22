---
id: "28"
title: "Near-threshold judged failures triaged: agents-md, handoff-decaying, feedback-loop-tighten"
status: in_progress
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

- [ ] Each def re-run solo ≥2× at unchanged content; classify: flaky (variance straddles threshold) vs genuine (stable miss)
- [ ] handoff-decaying: diff the a03798e handoff-skill change against the def's rubric before classifying — rule content regression in or out explicitly
- [ ] Flaky defs get variance remedy (trials increase per steering-pointer precedent) or rubric/task fix; genuine ones get a content fix or `known_gap` with rationale
- [ ] Baseline record 2026-07-19 amended with dispositions

## Out of scope

- Threshold/gate changes
- The 4 stable known gaps (type-error, prototype, code-review-security, cross-tool-planning)
