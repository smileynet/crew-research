---
id: "41"
title: "Roll out tkt: steering integration, archwright adoption, plan drift-check"
status: done
blocked_by: ["40", "45"]
env: either
spec: "ticket-cli"
---

# Roll out tkt: steering integration, archwright adoption, plan drift-check

## What to build

Make `tkt` the mechanical layer both repos actually use, per the enforcement split in
`.memory/specs/ticket-cli-spec.md` (Level 2 = tool, Level 4 = steering keeps selection
behavior and prose conventions).

Rescoped 2026-07-22 after the research sweep (decision record now in the spec): id
architecture settled — sequential ids kept, hash ids and dual-id rejected with revisit
triggers, `external:` reserved for GitHub/other correlation, distribution = documented
editable install. Hardening split out to ticket 45 (blocks this — edit/renumber reuse
the validated input paths).

- Update frontier-work steering (`atomics/skills/frontier-work/` or its steering module):
  replace the manual awk/fetch/rescan claim protocol with `tkt ready` / `tkt new` /
  `tkt claim`, keeping selection behavior (propose next, lowest-number-first) as prose;
  manual protocol demoted to fallback-when-tkt-absent
- `commit_files` multi-file commit helper in gitio: explicit paths only, staged set
  verified equal to the edit list (`git diff --cached --name-status`) before commit,
  loud failure on mismatch (pattern scope extension 2026-07-22)
- `tkt renumber <id> <new-id>` (R12): filename + id field + inbound blocked_by refs in
  one atomic commit via commit_files. Birth-window guidance: warns when the old id looks
  cited (any other ticket or docs/plan.md row references it) that prose/commit refs won't
  follow. Ambiguous old-id (duplicate) requires a filename argument; inbound refs are
  rewritten only when the old id is vacant after the move
- `tkt edit <id> [--blocked-by|--priority|--env|--spec|--title]` (field evidence: arch
  042 born with a wrong blocker; hand-edit had no tool support). Set semantics; empty
  string clears an optional field; surgical single-line edits
- `tkt sync-plan --check [path]` (R9): drift-check ticket status vs docs/plan.md-style
  `| NN | title | status |` tables. Report-only; JSON findings; crew exit contract
  (0=no drift, 1=drift, 2=crash). Rows whose ticket file no longer exists are ignored
  (archived history); open/in_progress tickets missing a row are warnings
- Batch create under a spec (R13): build only if trivial once commit_files exists
  (repeated `tkt new` is an acceptable alternative — SHOULD, not MUST); else spin off
- Docs: AGENTS.md Commands block + user-setup-guide replace the interim PYTHONPATH
  invocation with `uv tool install -e ./tools/tkt`; doctor.sh hints when tkt absent
- Archwright adoption: receiving-end ticket archwright#042 owns their conventions/wiring;
  this ticket owns crew-side steering + tool features + a mise-task (or fixture-suite
  hook) so `tkt validate` runs in their CI-equivalent

## Acceptance criteria

- [x] frontier-work steering references tkt for ready/new/claim; manual protocol text
      demoted to fallback-when-tkt-absent
- [x] `tkt validate` runs green in both repos' CI-equivalent (`mise run validate` here;
      archwright's fixture suite or a mise task there)
- [x] One real allocation in each repo done via `tkt new` (the birth run is the test —
      black-box by construction; crew: ticket 44; archwright: ticket 042 — 3-digit
      padding inferred correctly, both pushed first-attempt, 2026-07-21)
- [x] Renumber command proven on a fixture reproducing the 37↔39 collision shape;
      staged-set verification demonstrated (commit contains exactly the edit list)
- [x] R17 (black-box validation): renumber, edit, sync-plan --check (and batch if built)
      each land with subprocess-level acceptance tests (exit codes, output vs
      cli-outputs contract, file/git state — no internals)
- [x] Existing tickets in both repos still valid unchanged
- [x] docs/plan.md drift found by sync-plan --check on first run is fixed (row 44 et al.)

## Out of scope

- Cross-repo blocked_by, board view, owed-run ledger (COULDs — new tickets if wanted)
- Version floor R20 (COULD — trigger not met)
- `external:` field interpretation (reserved in contract; sync is a future ticket)

## Resolution (2026-07-22)

Built across 3dd0d04 (spec/design/plan currency), 6048e0e (ticket 45 hardening,
prerequisite), 7b457f2 (rollout commands + steering + install story).

- Steering: frontier-work rewritten tkt-first; manual claim protocol is the
  documented fallback-when-absent; tk warning retained
- Validate green in both CI-equivalents: crew `mise run validate` runs tkt validate;
  archwright `mise run validate:tickets` (f69f23d, their repo) — both corpora pass
- Renumber: duplicate-id (37↔39 shape) fixture proven black-box incl. --file
  disambiguation, refs-stay-while-occupied rule, quote-style preservation, cited-id
  warning; staged-set verification asserted (commit == exactly old+new+ref files,
  operator dirt excluded)
- sync-plan --check: caught REAL drift on first production run (row 45), fixed;
  PlanFinding leg added to cli-outputs.yaml (oracle-driven R17 test)
- R17: 9 new black-box tests; suite 45 passed; archwright-check 12/12; links pass
- Batch create (R13): spun off to ticket 46 — group-renumber retry loop nontrivial,
  repeated `tkt new` documented acceptable (used for 46's own birth)
- Install story: `uv tool install -e ./tools/tkt` documented (AGENTS.md), installed
  on this machine, doctor hints when absent. Extension-registration decision recorded
  in spec: documented install, NOT a tier extension (no conditional content)
