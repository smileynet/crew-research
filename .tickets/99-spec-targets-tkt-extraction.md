---
id: "99"
title: "Update spec check.target paths after tkt extraction"
status: open
blocked_by: []
---

# Update spec check.target paths after tkt extraction

## Context

`tkt` was extracted from `tools/tkt/` in this repo to its own standalone repo
at `~/code/tkt` (now a Rust crate). Three constraint specs still reference the
old path and fail static checks with "Target path not found":

- `design/specs/surgical-git-side-effects.md` → target: `tools/tkt`
- `design/specs/stage-only-ticket-file.md` → target: `tools/tkt/tkt`
- `design/specs/validate-reports-decay.md` → target: `tools/tkt`

## What to do

For each spec, decide:
1. **Retarget** — point `check.target` to the new tkt repo location (if the
   constraint still applies to the Rust rewrite)
2. **Mark pending** — set `target_status: pending` if the constraint needs
   rewriting for the new codebase (Rust vs Python, different structure)
3. **Archive** — if the constraint no longer applies post-extraction

Then run `archwright-check --static design/specs/ --target .` to confirm 0 failures.

## Acceptance criteria

- [ ] All three specs either pass static checks or are explicitly marked pending/archived
- [ ] `archwright-check --static` reports no target-not-found errors
