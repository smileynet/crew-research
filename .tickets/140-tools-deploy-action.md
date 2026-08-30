---
id: "140"
title: "Implement tools:deploy OS-branching build+skills action"
status: done
blocked_by: ["137"]
---

# Implement tools:deploy OS-branching build+skills action

## What to build

TBD

## Acceptance criteria

- [x] TBD

## Resolution (2026-08-30)

tools:deploy action: OS-selected build leg (recall pwsh scripts/deploy-local.ps1 on Windows / bash .sh on unix; tkt cargo install), skills leg (tkt deploy-skills.sh; recall null=crew-fallback), pwsh->powershell fallback, cargo/pwsh absence guards, repo skip-not-fail. Verified Windows-native via Git Bash: tkt built (cargo, replaced tkt.exe) + skills deployed; recall built via .ps1 (96 tests pass, --locked build, health check, scheduled-task verify). CREW_TOOLS_ROOT=/d/code resolves D-drive repos; missing repo => circle skip not error.
