---
kind: force
id: single-selection-reader
polarity: constraint
hardness: soft
evidence_level: L1
source: ".scratch/review/t144/crew-env-sites.md; job-tool-registry prior art"
serves: [pf-per-job-tool-selection, pf-env-policy]
---

# Single Selection Reader

## Statement

"Which legs run for job X on this machine" must be answered by ONE shared reader,
not re-implemented per harness script.

## Who Feels It

Maintainer

## Evidence

- Prior art (GitHub Actions matrix, Spring strategy+registry): selection lives in
  one schema, consumers reference keys only; the growing per-consumer switch is the
  documented anti-pattern (`.scratch/research/t144/job-tool-registry.md`).
- The canonical reason string `policy-blocked (CREW_ENV=corp)` is used at 6 sites but
  doctor.sh drifted to different wording — duplication already caused drift
  (`.scratch/review/t144/crew-env-sites.md` [L1:verified]).
