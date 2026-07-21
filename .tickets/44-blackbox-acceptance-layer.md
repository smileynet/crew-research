---
id: "44"
title: "Black-box acceptance layer: installed-artifact, output contracts, hook-based race test"
status: in_progress
blocked_by: ["40"]
env: either
spec: "ticket-cli"
---

# Black-box acceptance layer: installed-artifact, output contracts, hook-based race test

## What to build

Close the black-box coverage gaps in tkt's test suite (assessment 2026-07-21). The
existing suite exercises most commands through the subprocess boundary, but three gaps
mean the thing users actually run and the shapes agents actually consume are unverified:

1. **Installed-artifact smoke test.** Everything today runs via `PYTHONPATH` +
   `python -m tkt.cli`; the `uv tool install ./tools/tkt` → `tkt` console-script path is
   untested (the `npx cdk` failure class: entry-point/packaging breaks invisible to
   module-mode tests). Add a test (or mise task) that installs into a throwaway venv
   (`uv tool install --force` to a temp UV_TOOL_DIR, or `pip install` into a venv) and
   smoke-runs `tkt ready` + `tkt validate` through the binary on PATH.
2. **Output contract validation.** Machine-check real command output against
   `design/specs/cli-outputs.yaml`: every `query`/`ready --json` row has required
   TicketRow fields with contract types/enums; `validate` JSON has status∈{pass,fail,error},
   Finding rule/severity enums, and exit code coupled to status (0/1/2). Parse the
   contract spec YAML as the source of truth — no hand-duplicated field lists in the test.
3. **Hook-based race test.** Replace the `gitio.fetch` monkeypatch in
   `test_new_race_renumbers` with a `pre-receive` hook on the bare-remote fixture that
   rejects the first push (marker file), so the lost-race → renumber path runs end-to-end
   through real git semantics with zero knowledge of tkt internals. Keep the in-process
   variant only if it covers something the hook version cannot.

## Context

- Requirement R17 (added to `.memory/specs/ticket-cli-spec.md` with this ticket): every
  tkt command ships with black-box coverage — invoked through the public CLI surface,
  asserting only on exit codes, output, files, and git state.
- Existing black-box tests to build on: `tools/tkt/tests/test_tkt.py` (repo_pair fixture,
  run_tkt helper).
- The systematic long-game is archwright TRACE checking of the three behavior specs
  (ticket-lifecycle, claim-allocation-loop, frontier-selection) — blocked on the python
  stack adapter (Extension Protocol gap registered in `.memory/archwright-survey.md`;
  archwright-repo work, NOT this ticket).
- Ticket 41's rollout commands (renumber, sync-plan, batch create) carry the same R17
  bar via their AC — this ticket covers the MVP surface.

## Acceptance criteria

- [ ] Installed-artifact test: `tkt` console script installed into an isolated env and
      smoke-verified (ready + validate) through PATH, wired into `mise run test:tkt`
      (skips with reason if uv/venv unavailable)
- [ ] Contract test: query/ready/validate outputs machine-validated against
      `design/specs/cli-outputs.yaml` field/enum/exit-code rules, spec YAML as the oracle
- [ ] Race test runs via pre-receive hook (no monkeypatch); renumber output and final
      corpus state asserted black-box
- [ ] All existing tests still pass; suite runs green via `mise run test:tkt`

## Out of scope

- Trace-mode behavior-spec checking (python stack adapter — archwright repo)
- Black-box tests for ticket 41's new commands (they land with 41, under R17)
