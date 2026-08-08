---
id: "80"
title: "Spike: auto-detect Windows username in init.sh (WSL boundary layer 1)"
status: in_progress
blocked_by: []
priority: high
---

# Spike: auto-detect Windows username in init.sh (WSL boundary layer 1)

## Context

Proposal: `.scratch/proposals/wsl-boundary-resolution.md` (Layer 1)

Today's deploy failed because `$USER` in WSL is `user` but the Windows home is `C:\Users\uosmi`. Required manual `WIN_USERNAME=uosmi` override.

## What to build

Replace the brittle `${WIN_USERNAME:-$USER}` fallback in init.sh with auto-detection via `cmd.exe /C "echo %USERNAME%"` interop. Add validation and clear error messaging.

### Test plan

1. Unset `WIN_USERNAME`, run `wsl -- bash init.sh --global --tier full --tool kiro-cli` — should auto-detect `uosmi` and deploy to `/mnt/c/Users/uosmi/.kiro/`
2. With interop disabled (`/etc/wsl.conf` `[interop] enabled=false`): should fall back to `$USER` with a warning
3. With `WIN_USERNAME=uosmi` explicitly set: should use the override (backward-compatible)
4. When `/mnt/c/Users/$detected_user` doesn't exist: should warn and deploy to WSL home

## Acceptance criteria

- [ ] `wsl -- bash init.sh --global --tier full --tool kiro-cli` succeeds WITHOUT `WIN_USERNAME` being set
- [ ] Correct Windows username detected via `cmd.exe` interop
- [ ] Graceful degradation when interop is disabled (warning, not crash)
- [ ] Explicit `WIN_USERNAME` override still works (no regression)
- [ ] Clear error message when detected path doesn't exist
