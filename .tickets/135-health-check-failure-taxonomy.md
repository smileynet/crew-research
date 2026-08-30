---
id: "135"
title: "Verify matrix.sh --health failure-reason classification (4 of 5 classes untested)"
status: backlog
blocked_by: []
validation_criteria:
  - "each of model_unavailable/auth/quota/empty_or_timeout classifies correctly against a real induced error of that class, or untested reasons are labeled best-effort in README"
tags: ["kiro-v3"]
---

# Verify matrix.sh --health failure-reason classification (4 of 5 classes untested)

## Intent source

Ticket 134 (matrix.sh --health, done). Validation review 2026-08-29 surfaced that
only the healthy/unhealthy boolean + ONE failure reason (`server_error`) were
verified live. The classifier in `probe_model()` (tools/review/matrix.sh) also
maps `model_unavailable | auth | quota | empty_or_timeout` via regex on the JSONL
error event + stderr — but those 4 regexes were never exercised against a real
error of each class. The taxonomy is regex-only, unproven.

## Context

- Classifier: `probe_model()` in `tools/review/matrix.sh` — greps the last
  `type:"error"` JSONL event's `.error.data.message`/`.error.name` + stderr against
  the coding-plan-limits vocabulary.
- Only `server_error` proven (bogus model → opencode `UnknownError`).
- Vendor error shapes documented in `atomics/skills/coding-plan-limits/references/vendor-codes.md`
  (GLM numeric codes, Kimi error.type, Qwen message text) — the regexes should align to those.

## What to build

Either (A) induce one real error of each class and confirm the label, or (B) if a
class can't be induced safely/cheaply, downgrade it to documented best-effort:
- `model_unavailable` — probe a valid-provider/invalid-model id (e.g. `zai-coding-plan/glm-99`)
- `auth` — temporarily unset/corrupt one provider's key (revert after)
- `quota` — hard to force on demand; likely (B) best-effort, or capture opportunistically if a plan caps during normal use
- `empty_or_timeout` — set TIMEOUT very low (e.g. 1s) to force a timeout → empty stream

Then either confirm each regex fires OR mark unverified reasons "best-effort" in
tools/review/README.md so the summary's reason field isn't over-trusted for remediation.

## Acceptance criteria

- [ ] `model_unavailable` verified against a real invalid-model probe (or best-effort labeled)
- [ ] `auth` verified against a real auth failure (or best-effort labeled)
- [ ] `empty_or_timeout` verified via a forced low-timeout probe
- [ ] `quota` verified opportunistically or documented as best-effort/unforceable
- [ ] README states which reasons are verified vs best-effort; regexes aligned to vendor-codes.md
- [ ] `bash -n` + lint pass

## Out of scope

- The healthy/down boolean + server_error (already verified in 134)
- Changing the health mechanism itself (just the reason-classification accuracy)

TBD

## Acceptance criteria

- [ ] TBD
