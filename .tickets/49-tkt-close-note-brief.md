---
id: "49"
title: "tkt ergonomics: close --note and --brief output for validate/sync-plan"
status: open
blocked_by: []
env: either
spec: "ticket-cli"
---

# tkt ergonomics: close --note and --brief output for validate/sync-plan

## What to build

Two small ergonomics additions to tkt, both traced to repeated manual work
(guidance-sync P4, 2026-07-22 + 07-23 sessions):

1. **`tkt close <id> --note "..."`** — writes the given text into the Resolution
   section instead of the `TBD` placeholder. Without `--note`, behavior is unchanged
   (stub with TBD). Multi-line via literal `\n` or repeated flag is NOT needed —
   sessions that want rich Resolutions keep editing the file; `--note` covers the
   one-liner case. Incident: the TBD stub was hand-replaced 3× in one session
   (tickets 48, 27, 28).

2. **`--brief` flag on `validate` and `sync-plan --check`** — human-readable summary
   to stdout (one line per finding + a status line) instead of the JSON document.
   JSON remains the default (validation contract unchanged — `--brief` is presentation
   only; exit codes identical). Incident: the same inline-python JSON summarizer was
   written 5× across two sessions; flagged 07-22 with "revisit if it recurs" — it did.

## Context

- **Files:** `tools/tkt/tkt/cli.py` (close, validate, sync-plan handlers)
- **Contract:** `design/specs/cli-outputs.yaml` — check whether stdout shape is
  contracted for these commands; if so, `--brief` needs a contract note (flag-gated
  alternate presentation, JSON default preserved)
- **Suite:** `mise run test:tkt` (45 tests) — add cases for both flags
- **Design Gate check:** no force tension (presentation-only + optional param), no new
  durable invariants (JSON default preserved), no rejected alternatives worth recording
  → build directly, no pipeline run needed

## Acceptance criteria

- [ ] `tkt close <id> --note "text"` writes the note into the Resolution section;
      without the flag, current TBD-stub behavior is byte-identical
- [ ] `tkt validate --brief` and `tkt sync-plan --check --brief` print one line per
      finding + a final status line; exit codes match JSON mode exactly
- [ ] JSON output without `--brief` is byte-identical to current (contract tests pass)
- [ ] Static checks pass (`mise run check:design`); cli-outputs contract updated if
      stdout shape is contracted
- [ ] Test suite extended to cover both flags; `mise run test:tkt` green
