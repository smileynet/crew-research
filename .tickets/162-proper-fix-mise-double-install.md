---
id: "162"
title: "Proper fix: remove double mise install so shims are durable (161 reshim was a band-aid)"
status: in_progress
blocked_by: []
priority: high
---

# Proper fix: remove double mise install so shims are durable

## Intent source

Follow-up to ticket 161. The `mise reshim` applied there made `tkt` work for one session but
`mise doctor` now reports "shims are missing" and the `tkt.exe` shim is gone again — the reshim
papered over the cause. Full diagnosis + options: `.scratch/mise-proper-fix-proposal.md`.
User agreed to Option A (2026-09-17).

## Root cause

Two competing mise installs; shims (the only activation path — no profile runs `mise activate`)
can't reliably reach the authoritative mise:
- **winget mise 2026.8.10** (symlink → `WinGet\Packages\jdx.mise_…\mise\bin\mise.exe`) owns
  `~\AppData\Local\mise\shims`, but its resolved Packages bin lacks `mise-shim.exe`.
- **cargo mise 2026.8.5** (`D:\dev-tools\cargo\bin`) is the stale duplicate that
  `mise which mise` wrongly resolves to → delegation loop / recursion.

## Fix (Option A)

1. `mise self-update` (winget mise → 2026.9.10) [or `winget upgrade jdx.mise`].
2. `cargo uninstall mise` — remove the stale duplicate. **Keep `tkt`** (real tool in the same
   cargo bin).
3. Make shim mode deterministic: `mise settings set windows_shim_mode file` (declares the mode
   instead of relying on a silent fallback), OR place `mise-shim.exe` next to the resolved
   winget binary.
4. `mise reshim`.

## Acceptance criteria

- [ ] Only one mise on PATH resolves as authoritative; `mise which mise` no longer points at a removed/looping binary
- [ ] `mise doctor` reports NO "shims are missing" and no recursion warning
- [ ] `~\AppData\Local\mise\shims\tkt.exe` exists after reshim
- [ ] Bare `tkt ready` works from a fresh `cmd` AND PowerShell (no direct-binary workaround)
- [ ] `mise run generate -- codex` still expands the arg (issue 2 regression check)
- [ ] `tkt` (real tool) still installed and runnable

## Out of scope

- Issue 2 (usage-arg) — already fixed at user-config level (161)
- Moving the plaintext secrets in `~/.config/mise/config.toml` (flagged separately)

## References

- Proposal: `.scratch/mise-proper-fix-proposal.md`
- Predecessor: ticket 161 (reshim band-aid + issue-2 fix + docs)
