---
kind: force
id: pf-per-job-tool-selection
polarity: desire
evidence_level: L2
source: "tickets 142/143/144; 6 duplicated CREW_ENV enforcement sites"
serves: []
---

# Pf Per Job Tool Selection

## Statement

The operator wants to choose which tools/harnesses participate in each job type
(eval, judge, code review, proof) without editing per-harness scripts.

## Who Feels It

Operator

## Evidence

- Tickets 142/143 each added a reviewer leg by editing code — the pattern doesn't
  scale across tool × job-type (ticket 144 intent).
- The corp/agy conditional is duplicated in 6 code locations across 5 files
  (init.sh, doctor.sh, run-proof.sh, run.sh ×2, matrix.sh) — `.scratch/review/t144/crew-env-sites.md` [L1:verified].
- machine-to-machine tool differences (ticket 131 codex blocker) are hard-coded
  rather than configured.
