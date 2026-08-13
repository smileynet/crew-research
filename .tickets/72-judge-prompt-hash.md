---
id: "72"
title: "Include the judge prompt/rubric in the identity scheme so template edits read as drift"
status: done
blocked_by: []
env: either
spec: "eval-harness"
---

# Include the judge prompt/rubric in the identity scheme so template edits read as drift

## What to build

The identity scheme (ticket 33) covers three components: `skill_hash` (skills + steering),
`def_hash` (definition yaml + fixtures), `env_id` (adapter, tool version, model, judge
set). The judge prompt and rubric live in `run.sh`'s `judge_output()` and are covered by
none of them — so editing the judge template silently changes every score with no
staleness signal, while a one-word fixture change is caught.

This is not hypothetical: prompt rewording flipped majority verdicts in 25% of cases in
one 2026 study, and PoLL measured a judge's kappa moving 0.518→0.725 across prompt
variants (and prompts did not transfer between judges).

Add a fourth component — `judge_hash` — over the judge prompt template, rubric, and
scoring mode. Follow the existing contract in `identity.sh`: one hashing implementation
shared by `run.sh` and `check-staleness.sh`, relative paths only, missing inputs
contribute a `MISSING:` line rather than crashing.

Design note to settle: the template is currently a heredoc inside `run.sh`, so hashing it
means either hashing a source range (brittle) or extracting the template to its own file
(cleaner, and makes the judge prompt reviewable in diffs). Prefer extraction.

## Acceptance criteria

- [x] `judge_hash` recorded on every scored row and recomputable by `check-staleness.sh`
- [x] Editing the judge prompt reports JUDGE-DRIFT; editing an unrelated part of run.sh
      does not
- [x] Extraction (if taken) leaves judging behaviour byte-identical — verify by
      re-judging one retained def before and after and diffing the prompts, not the
      scores (scores are nondeterministic)
- [x] `check-staleness.sh` drift kinds documented together in one place
- [x] Rows predating the component read as unknown, not current

## Resolution (2026-07-29)

Judge template extracted to judge-template.txt; judge_hash (4th identity component) emitted in rows and checked for JUDGE-DRIFT. Backward-compatible: pre-ticket rows treated as unknown.
