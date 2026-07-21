---
id: "44"
title: "Black-box acceptance layer: installed-artifact, output contracts, hook-based race test"
status: done
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

- [x] Installed-artifact test: `tkt` console script installed into an isolated env and
      smoke-verified (ready + validate) through PATH, wired into `mise run test:tkt`
      (skips with reason if uv/venv unavailable)
- [x] Contract test: query/ready/validate outputs machine-validated against
      `design/specs/cli-outputs.yaml` field/enum/exit-code rules, spec YAML as the oracle
- [x] Race test runs via pre-receive hook (no monkeypatch); renumber output and final
      corpus state asserted black-box
- [x] All existing tests still pass; suite runs green via `mise run test:tkt`

## Out of scope

- Trace-mode behavior-spec checking (python stack adapter — archwright repo)
- Black-box tests for ticket 41's new commands (they land with 41, under R17)

## Resolution (2026-07-21)

Built in commit 6bb0f5d. `tools/tkt/tests/test_blackbox.py` + shared `conftest.py`.

- **Installed-artifact**: `uv tool install` into isolated UV_TOOL_DIR/UV_TOOL_BIN_DIR,
  `tkt ready` + `tkt validate` run through PATH with PYTHONPATH scrubbed (source tree
  cannot mask packaging breaks). Skips with reason when uv absent. In `mise run test:tkt`
  (directory-scoped pytest picks it up).
- **Contract**: `_check_schema` validates rows/findings against `cli-outputs.yaml`
  parsed at test time — required fields, enum values, contract types, undeclared-field
  drift check, optional-field present-only-when-set, extensions preservation, exit-code
  coupling (0/pass, 1/fail, 2/crash). Vacuity-probed: catches missing-required,
  bad-enum, wrong-type, undeclared; clean row passes.
- **Race**: pre-receive hook on the bare remote promotes a pre-staged snipe ref onto
  main and rejects B's first push — lost-race -> renumber runs subprocess-only through
  real git. Asserts renumber output, remote main corpus, id-field rewrite, clean
  validate. Monkeypatch variant removed (hook covers a strict superset).
- Suite: 17 passed (was 13; -1 removed race test, +5 black-box). archwright-check
  12/12 PASS after change.
