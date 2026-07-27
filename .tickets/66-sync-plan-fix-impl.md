---
id: "66"
title: "Implement sync-plan --fix for derivable status columns"
status: open
blocked_by: ["64"]
spec: "ticket-cli"
---

# Implement sync-plan --fix for derivable status columns

## What to build

Add `--fix` flag to `tkt sync-plan` that auto-updates safe/derivable columns in
`docs/plan.md` tables to match ticket frontmatter state. Design per R9a decision
in `.memory/specs/ticket-cli-spec.md`.

## Context

- Decision: ticket 64 research (2026-07-27), recorded as R9a in spec
- Scope: Ruff-model safe/unsafe/manual classification
- Default behavior unchanged: `sync-plan` without `--fix` remains report-only (R9)

## Design (from R9a)

Safe columns (auto-fixed by `--fix`):
- Status: updated to match ticket `status:` frontmatter
- Blocked By: updated to match ticket `blocked_by:`

Unsafe columns (reported as warnings, never auto-fixed):
- Title drift (ticket title ≠ plan row title)
- Missing rows (ticket exists, no plan entry)
- Extra rows (plan entry, no matching ticket)

Manual columns (never touched, never reported):
- Narrative, Notes, Spec, any other human-authored content

## Acceptance criteria

- [ ] `tkt sync-plan --fix` updates status and blocked_by columns in plan table rows
- [ ] Non-derivable drift reported as warnings (not fixed)
- [ ] Exit code contract: 0=all drift resolved, 1=unsafe drift remains, 2=crash
- [ ] `tkt sync-plan` (no --fix) behavior unchanged (report-only, same exit codes)
- [ ] Markdown table formatting preserved (cell widths, alignment)
- [ ] Test: plan with 3 stale status cells → --fix corrects all 3, exits 0
- [ ] Test: plan with title drift → --fix corrects status but exits 1 (unsafe remains)
- [ ] Test: plan with no drift → --fix is a no-op, exits 0

## Out of scope

- Row insertion/deletion (unsafe — human judgment required)
- Non-plan.md targets
- Interactive mode or confirmation prompts
