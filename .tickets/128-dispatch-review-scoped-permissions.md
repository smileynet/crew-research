---
id: "128"
title: "Scoped reviewer permissions (opencode + codex) — optional hardening; yolo is the default"
status: backlog
blocked_by: []
---

# Scoped reviewer permissions (opencode + codex) — optional hardening

## Decision

**Yolo is the standard in ALL cases for now** — `opencode run --auto` and
`codex exec --dangerously-bypass-approvals-and-sandbox`. Reviewers need to read
the tree, run tests/linters, and (codex path) push a findings ticket, so full
permission is the pragmatic default. This ticket is the OPTIONAL hardening to
apply IF/WHEN yolo causes a problem (accidental write to the live tree, a
runaway command, a security concern in a shared repo). Backlog until then.

## Context — two reviewer paths, both yolo, different reasons

| Reviewer | Current flag | What it means |
|----------|-------------|---------------|
| opencode | `--auto` | Auto-approves anything not explicitly denied. opencode has NO OS sandbox — permission-based only. |
| codex | `--dangerously-bypass-approvals-and-sandbox` | Skips BOTH approval prompts AND the OS sandbox. Codex's own help: "EXTREMELY DANGEROUS. Intended solely for externally-sandboxed environments." |

Both are effectively yolo, but codex bypasses a real sandbox whereas opencode
never had one. The mitigation already in place: reviewers run in a throwaway git
worktree (matrix.sh B9), so accidental writes hit the disposable checkout, not the
live tree.

## What to build (if hardening is triggered)

**opencode** (research `.scratch/research/t127/opencode-headless.md`):
1. Restricted agent (preferred): `mode: subagent`, `permission: { edit: deny, webfetch: deny, bash: { "*": "allow", "rm *": "deny" } }`, invoked `opencode run --agent review`.
2. Or `OPENCODE_PERMISSION` env / `opencode.json` inline policy.

**codex**: swap `--dangerously-bypass-approvals-and-sandbox` → `-s workspace-write`
(can read + run tests + write within the workspace, but no full-access/network
and approval prompts still gated by the mode). Enough for a review that runs tests
and writes a findings ticket; drops the "bypass everything" hammer. Verify against
the codex env blocker (tkt#131) — needs a working codex model first.

Keep yolo as an explicit opt-in escape hatch in both cases.

## Acceptance criteria

- [ ] opencode reviewer: scoped policy (edit denied) by default; can still run tests + read tree; `--auto` opt-in retained
- [ ] codex reviewer: `-s workspace-write` (or narrower) by default; can run tests + write the ticket; full bypass opt-in retained
- [ ] Both verified to complete a review under the scoped policy (no hang on approval prompts)
- [ ] Worktree isolation (B9) retained as defense-in-depth regardless of policy
- [ ] Documented in tools/review/README.md + dispatch-review model-matrix.md + result-contract.md
