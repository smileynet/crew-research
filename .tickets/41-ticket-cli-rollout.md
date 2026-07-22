---
id: "41"
title: "Roll out tkt: steering integration, archwright adoption, plan drift-check"
status: in_progress
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

- [ ] frontier-work steering references tkt for ready/new/claim; manual protocol text
      demoted to fallback-when-tkt-absent
- [ ] `tkt validate` runs green in both repos' CI-equivalent (`mise run validate` here;
      archwright's fixture suite or a mise task there)
- [x] One real allocation in each repo done via `tkt new` (the birth run is the test —
      black-box by construction; crew: ticket 44; archwright: ticket 042 — 3-digit
      padding inferred correctly, both pushed first-attempt, 2026-07-21)
- [ ] Renumber command proven on a fixture reproducing the 37↔39 collision shape;
      staged-set verification demonstrated (commit contains exactly the edit list)
- [ ] R17 (black-box validation): renumber, edit, sync-plan --check (and batch if built)
      each land with subprocess-level acceptance tests (exit codes, output vs
      cli-outputs contract, file/git state — no internals)
- [ ] Existing tickets in both repos still valid unchanged
- [ ] docs/plan.md drift found by sync-plan --check on first run is fixed (row 44 et al.)

## Out of scope

- Cross-repo blocked_by, board view, owed-run ledger (COULDs — new tickets if wanted)
- Version floor R20 (COULD — trigger not met)
- `external:` field interpretation (reserved in contract; sync is a future ticket)
