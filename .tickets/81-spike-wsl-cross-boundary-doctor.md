---
id: "81"
title: "Spike: cross-boundary tool verification in doctor.sh (WSL boundary layer 2)"
status: in_progress
blocked_by: []
priority: high
---

# Spike: cross-boundary tool verification in doctor.sh (WSL boundary layer 2)

## Context

Proposal: `.scratch/proposals/wsl-boundary-resolution.md` (Layer 2)

Doctor reports `❌ kiro-cli not found` when run from WSL, but kiro-cli is installed on Windows and works fine. The check uses `command -v` which only finds Linux binaries.

## What to build

When doctor detects it's running in WSL, verify tools on the Windows side via `cmd.exe /C "tool --version"`. Add WSL interop health check. Report which side a tool was found on.

### Test plan

1. Run `wsl -- bash doctor.sh --project <path>` — kiro-cli should show ✅ with `[Windows]` tag
2. Verify jq detection works via Windows interop
3. Test with a tool that exists on BOTH sides — should prefer Linux-native, note both
4. Test with interop disabled — should report interop failure, degrade to Linux-only checks
5. Measure overhead: time the full doctor run to confirm <3s total

## Acceptance criteria

- [ ] `wsl -- bash doctor.sh` reports kiro-cli ✅ via Windows interop
- [ ] jq detected via Windows side when not installed in WSL
- [ ] WSL interop health check runs first; reports clearly if broken
- [ ] Tool output labels show which side (`[Windows]` vs native)
- [ ] No regression when run from Git Bash, native Linux, or macOS
- [ ] Total doctor runtime <3s on a warm WSL session
