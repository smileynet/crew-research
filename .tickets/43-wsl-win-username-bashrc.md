---
id: "43"
title: "WSL bashrc should export WIN_USERNAME for deploy reliability"
status: done
blocked_by: []
env: either
spec: ""
---

# WSL bashrc should export WIN_USERNAME for deploy reliability

## What to build

Add `export WIN_USERNAME=<windows-user>` to the WSL `~/.bashrc` so that `init.sh`, `doctor.sh`, and any future scripts that reference `${WIN_USERNAME:-$USER}` resolve to the correct Windows home without manual intervention.

## Context

- **Observed (2026-07-19):** deploy from WSL went to `/home/user/.kiro` (WSL home) instead of `/mnt/c/Users/uosmi/.kiro` (Windows home) because:
  1. WSL `$USER` is `user`, not `uosmi`
  2. `cmd.exe /C "echo %USERNAME%"` returned empty (the resolution pattern from AGENTS.md failed silently)
  3. init.sh's fallback `${WIN_USERNAME:-$USER}` resolved to `user`, `/mnt/c/Users/user` didn't exist, so it fell back to `$HOME`
- The fix is trivial: `export WIN_USERNAME=uosmi` in `~/.bashrc` before any crew-research scripts run.
- This also benefits `tools/recall/bashrc-hook.sh` (which calls ingest scripts that may need the Windows home) and the future doctor.sh WSL fix (ticket 39).

## Acceptance criteria

- [x] WSL `~/.bashrc` contains `export WIN_USERNAME=uosmi`
- [ ] `wsl -- bash -c 'echo $WIN_USERNAME'` returns `uosmi`
- [ ] Deploy via `wsl -- bash -c '... init.sh --global ...'` targets `/mnt/c/Users/uosmi/.kiro` without needing a manual `export`

## Out of scope

- Fixing why `cmd.exe /C "echo %USERNAME%"` returns empty (Windows/WSL interop issue — unreliable in non-interactive shells)
- Making init.sh auto-detect without WIN_USERNAME (ticket 39 may address this for doctor.sh)

## Resolution
**Closed:** 2026-07-20 (Resolution backfilled 2026-07-22). `export WIN_USERNAME` added to the WSL `~/.bashrc` so init.sh/doctor.sh resolve the Windows home (`/mnt/c/Users/uosmi`) instead of falling back to the WSL home during deploys. Evidence: docs/plan.md row 43 ("✅ done"); close commit 711d991 ("both fixes applied and verified" — the fix for this ticket is off-repo machine state).
Closed pre-tkt; unchecked ACs were not individually verified at close.
