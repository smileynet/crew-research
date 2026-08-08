---
id: "82"
title: "Spike: extension prereq check via WSL interop (WSL boundary layer 3)"
status: in_progress
blocked_by: []
priority: high
---

# Spike: extension prereq check via WSL interop (WSL boundary layer 3)

## Context

Proposal: `.scratch/proposals/wsl-boundary-resolution.md` (Layer 3)

Doctor's `_check_prereq` has a Git Bash/MSYS2 PowerShell fallback but no WSL-specific path. Result: `recall --version` fails from WSL even though recall is installed on Windows via uv. Extension marked as "prerequisite not met" when it shouldn't be.

## What to build

Add WSL to the `_check_prereq` fallback chain. When direct invocation fails in WSL, try `cmd.exe /C "command"` and then `powershell.exe -Command "command"` before declaring the prereq unmet.

### Test plan

1. Run `wsl -- bash doctor.sh` with recall installed on Windows (uv tool) — extension should show ✅
2. Run with recall NOT installed — should still correctly report "prerequisite not met"
3. Run from Git Bash — existing MSYS2 PowerShell fallback should still work (no regression)
4. Run from native Linux without the tool — should report not met without trying Windows fallbacks
5. Verify the recall health check (`recall health --json`) also works through the interop path

## Acceptance criteria

- [ ] Recall extension prereq passes from WSL doctor when recall is installed on Windows
- [ ] Extension correctly reports "not met" when tool genuinely missing
- [ ] Existing Git Bash/MSYS2 fallback preserved (no regression)
- [ ] Recall health JSON retrieved successfully via interop fallback
- [ ] Fallback chain order: direct → cmd.exe → powershell.exe → fail
