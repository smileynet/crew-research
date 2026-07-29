---
id: "73"
title: "Declare a canonical judge panel and flag machine-local deviations"
status: open
blocked_by: ["70"]
env: either
spec: "eval-harness"
---

# Declare a canonical judge panel and flag machine-local deviations

## What to build

Panel composition varies by machine: corp loses agy by policy, codex is environment
dependent, crush needs a Bedrock id on corp and runs GLM on personal. `env_id` already
encodes the live judge set, so the variation is visible — but there is nothing to compare
it *against*. "Degraded" is currently computed from counts alone (≥3 judges, ≥2 families),
which a machine can satisfy with a completely different panel than another machine.

Declare the canonical panel in `judges/default.yaml` (the intended set, not the live set)
and have the harness report deviation from it: same-size-but-different-legs is a real
comparability break that today reads as clean.

Scope note: this is reporting, not enforcement. A machine that cannot run the canonical
panel must still be able to run evals — it just must not claim comparability.

## Acceptance criteria

- [ ] Canonical panel declared in one place, with the reasoning for its composition
- [ ] Runs report canonical vs live: matching, degraded (below floor), or deviating
      (at-floor but different legs)
- [ ] Deviation appears in meta.json and in the run summary, not only per row
- [ ] `env_id` semantics unchanged (it stays a readable composed string; deviation is
      derived, not baked into the id)
- [ ] Cross-machine interchange (ticket 32) still joins rows from a deviating machine —
      deviation must not silently exclude data
