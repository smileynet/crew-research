---
id: "37"
title: "doctor.sh checks WSL $HOME instead of the Windows deploy home"
status: open
blocked_by: []
env: either
spec: ""
---

# doctor.sh checks WSL $HOME instead of the Windows deploy home

## What to build

Port init.sh's `DEPLOY_HOME` detection (init.sh lines 14-20: WSL → `/mnt/c/Users/$WIN_USER`) into doctor.sh, and use it for every home-relative check.

## Context

- **Observed (2026-07-19, corp machine):** after removing a dead WSL-native `/home/<user>/.kiro`, running doctor inside WSL reported 25 errors — "No global deployment", every steering/skill "missing" — while the real deployment in `/mnt/c/Users/<user>/.kiro` was healthy (verified: tier reconciliation clean when run with `HOME=/mnt/c/Users/<user>`).
- init.sh deploys to `DEPLOY_HOME` (Windows home when in WSL); doctor.sh reads `~/.kiro`, `$HOME/.codex`, `$HOME/.gemini`, `$HOME/.config/crush`, `~/.recall/last_ingest` etc. via plain `$HOME` (~34 sites).
- Workaround until fixed: run doctor with `HOME=/mnt/c/Users/<user>` — but that breaks tool checks (kiro-cli/jq "not found") and the recall staleness check, so it's not a real substitute.

## Acceptance criteria

- [ ] doctor.sh resolves the same `DEPLOY_HOME` init.sh deploys to (WSL detection + `WIN_USERNAME` override)
- [ ] All deployment-artifact checks (steering, skills, manifests, tier stamp, per-tool AGENTS.md paths, recall staleness marker) use `DEPLOY_HOME`
- [ ] Tool availability checks (kiro-cli, yq, jq…) still use the running environment's PATH, not DEPLOY_HOME
- [ ] On a WSL+Windows machine with no WSL-native ~/.kiro: doctor run from WSL reports the same result as the Windows-home state (no false missing errors)
- [ ] Non-WSL Linux/macOS behavior unchanged

## Out of scope

- Making doctor runnable natively on Windows (it stays bash)
- agy policy checks (ticket 36)
