---
id: "128"
title: "Scoped reviewer permissions (opencode + codex) — optional hardening; yolo is the default"
status: backlog
blocked_by: []
---

# Scoped opencode permissions for review (read-only agent, drop blanket --auto)

## Context

Ticket 127's matrix.sh + opencode adapter use blanket `--auto` (auto-approve any
permission not explicitly denied). opencode has NO OS-level sandbox — it's
permission-based. `--auto` lets a reviewer edit source, run arbitrary shell, and
fetch the web, which is more than a review task needs.

**Current decision: keep `--auto` (yolo) until issues are encountered.** This
ticket captures the hardening for when they are.

## What to build

Replace blanket `--auto` with a scoped read-only reviewer policy, keeping `--auto`
only as an opt-in escape hatch. Two viable mechanisms (research `.scratch/research/t127/opencode-headless.md`):

1. **Restricted agent** (preferred): a `mode: subagent` opencode agent
   `permission: { edit: deny, webfetch: deny, bash: { "*": "allow", "rm *": "deny" } }`,
   invoked `opencode run --agent review ...`. A review reads + runs tests + git; it
   should not edit source.
2. **`OPENCODE_PERMISSION` env / `opencode.json`**: inline JSON policy per run.

Wire the chosen mechanism into `tools/review/matrix.sh` and the adapter
`dispatch_review` block. Verify the reviewer can still run tests + read the tree
under the restricted policy (the review methodology needs subprocess exec).

## Acceptance criteria

- [ ] matrix.sh uses a scoped read-only-ish reviewer policy by default (edit denied)
- [ ] Reviewer can still run tests/linters + read the working tree under the policy
- [ ] `--auto` remains available as an explicit opt-in escape hatch
- [ ] Documented in tools/review/README.md + dispatch-review model-matrix.md
- [ ] Verified: a review run completes under the scoped policy (no hang on ask prompts)
