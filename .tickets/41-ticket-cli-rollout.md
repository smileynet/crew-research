---
id: "41"
title: "Roll out tkt: steering integration, archwright adoption, plan drift-check"
status: in_progress
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
  under a spec (R13). Consider `tkt edit <id> --blocked-by/--priority/...` alongside
  renumber: field evidence 2026-07-21 — a wrong `--blocked-by` at new-time (arch 042
  blocked on unrelated 040) had no tool-supported correction; hand-edit + second commit
  was the workaround
- Archwright adoption: receiving-end ticket exists — archwright#042 (filed 2026-07-21 by
  operator directive, allocated via `tkt new` from that repo). This ticket owns the crew
  side (steering, tool features); 042 owns archwright-side conventions/wiring
- Extension registration decision: does `tkt` become a tier extension (auto-detect on
  PATH, like recall) or stay a documented install? Record the choice in the spec

## Acceptance criteria

- [ ] frontier-work steering references tkt for ready/new/claim; manual protocol text
      demoted to fallback-when-tkt-absent
- [ ] `tkt validate` runs green in both repos' CI-equivalent (`mise run validate` here;
      archwright's fixture suite or a mise task there)
- [x] One real allocation in each repo done via `tkt new` (the birth run is the test —
      black-box by construction; crew: ticket 44; archwright: ticket 042 — 3-digit
      padding inferred correctly, both pushed first-attempt, 2026-07-21)
- [ ] Renumber command proven on a fixture reproducing the 37↔39 collision shape
- [ ] R17 (black-box validation, `.memory/specs/ticket-cli-spec.md`): renumber,
      sync-plan --check, and batch create each land with subprocess-level acceptance
      tests (exit codes, output vs cli-outputs contract, file/git state — no internals)
- [ ] Existing tickets in both repos still valid unchanged

## Out of scope

- Cross-repo blocked_by, board view, owed-run ledger (COULDs — new tickets if wanted)
