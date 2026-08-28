---
id: "129"
title: "Per-model review markers for uneven progress + resume"
status: backlog
blocked_by: []
---

# Per-model review markers for uneven progress + resume

## Context

Ticket 127's `result-contract.md` specifies a `.review/review-marker.json` with a
plural `reviewers[]` array, each entry carrying its own `reviewed_through`
coverage boundary. But `tools/review/matrix.sh` neither writes nor reads it — it
only emits an ephemeral per-run `manifest.json` + `matrix-summary.json` in
`.scratch/`. So the marker is spec-only today.

Consequence: every model reviews the same `TARGET` in one shot. If GLM is
quota-exhausted after covering W..X while Kimi covers W..TARGET, the run can only
mark GLM `indeterminate` for the WHOLE run — it can't record "GLM reached X,
resume from there." No uneven-progress support, no resume.

## What to build

Implement the `.review/review-marker.json` `reviewers[]` coverage ledger in the
matrix flow:

1. **Write** per-model `reviewed_through` after each reviewer completes (parent
   fan-in owns the write — single writer, no race; migrate legacy
   `.codex/review-marker.json` schema-1 as `reviewer:"codex"`).
2. **Read** on a subsequent run: each model resumes from its own
   `reviewed_through`, not the global TARGET. A quota-exhausted model resumes
   where it stopped instead of restarting.
3. **Coverage policy** (`any-of | all-of | k-of-N` + `required_reviewers`): define
   "complete" over the reviewer set; a lagging model = reported coverage gap, not
   silent success. (See review-marker-multimodel research.)

Keep finding attribution (`Reviewer:`/`Agreement:`) in the ticket, separate from
the marker ("who looked where" vs "who said what").

## Acceptance criteria

- [ ] matrix flow writes per-model `reviewed_through` to `.review/review-marker.json` reviewers[]
- [ ] A re-run resumes each model from its own boundary (uneven progress supported)
- [ ] Quota-exhausted model resumes where it stopped, not from scratch
- [ ] Coverage policy (any-of/all-of/k-of-N) determines run completeness; gaps reported
- [ ] Legacy `.codex/review-marker.json` migrates as reviewer:"codex" (Codex path unchanged)
