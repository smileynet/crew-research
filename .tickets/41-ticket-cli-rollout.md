---
id: "41"
title: "Roll out tkt: steering integration, archwright adoption, plan drift-check"
status: open
blocked_by: ["40"]
env: either
spec: "ticket-cli"
---

# Roll out tkt: steering integration, archwright adoption, plan drift-check

## What to build

Make `tkt` the mechanical layer both repos actually use, per the enforcement split in
`.memory/specs/ticket-cli-spec.md` (Level 2 = tool, Level 4 = steering keeps selection
behavior and prose conventions).

- Update frontier-work steering (`atomics/skills/frontier-work/` or its steering module):
  replace the manual awk/fetch/rescan claim protocol with `tkt ready` / `tkt new` /
  `tkt claim`, keeping selection behavior (propose next, lowest-number-first) as prose
- Deferred SHOULDs from ticket 40: `tkt renumber` (R12 — filename + id + inbound
  blocked_by refs atomically), `tkt sync-plan --check` (R9 — drift-check ticket status vs
  docs/plan.md-style tables; generate later only if drift keeps recurring), batch create
  under a spec (R13)
- Archwright adoption: install note in its AGENTS.md / plan conventions; verify `tkt`
  handles its repo end-to-end (3-digit ids, `created:`/`closed:` legacy fields, PLAN.md
  NEXT UP pointer stays prose)
- Extension registration decision: does `tkt` become a tier extension (auto-detect on
  PATH, like recall) or stay a documented install? Record the choice in the spec

## Acceptance criteria

- [ ] frontier-work steering references tkt for ready/new/claim; manual protocol text
      demoted to fallback-when-tkt-absent
- [ ] `tkt validate` runs green in both repos' CI-equivalent (`mise run validate` here;
      archwright's fixture suite or a mise task there)
- [ ] One real allocation in each repo done via `tkt new` (the birth run is the test)
- [ ] Renumber command proven on a fixture reproducing the 37↔39 collision shape
- [ ] Existing tickets in both repos still valid unchanged

## Out of scope

- Cross-repo blocked_by, board view, owed-run ledger (COULDs — new tickets if wanted)
