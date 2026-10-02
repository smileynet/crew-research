---
id: "173"
title: "Add a hooks deploy/prune artifact class to init.sh/doctor.sh (prereq for shipping global hooks)"
status: open
blocked_by: []
tags: [kiro-v3]
---

# Hooks deploy/prune artifact class

## Why

crew-research's `init.sh`/`doctor.sh` lay down + prune skills and steering (tracked
in `~/.kiro/.crew-skills`) but have NO artifact class for kiro-cli v3 hooks
(`~/.kiro/hooks/*.json`). Global hooks fire shell in EVERY workspace, so shipping
one (ticket 174) without a managed lay-down + prune manifest would leave orphaned
hooks on redeploy and run commands in unrelated projects. This ticket builds the
mechanism so hook-shipping tickets have a safe home.

## Design decision (ADR-worthy)

A global hook is a new always-on, side-effecting artifact (runs shell per workspace).
Decide + record: (a) managed class with a `~/.kiro/.crew-hooks` prune manifest
mirroring `.crew-skills`, OR (b) the existing symlink convention (user owns the file,
init just detects). Factors: prune safety, opt-in gating (hooks must respect
`--skip-extension`), doctor health reporting, portability (hooks are kiro-only — other
tools ignore the class).

## What to build

- init.sh: optional hooks lay-down from a tier/extension manifest → `~/.kiro/hooks/`,
  tracked in `~/.kiro/.crew-hooks`; prune removes only crew-managed hooks (never
  user/other-tool hooks). Respect env gating + `--skip-extension`.
- doctor.sh: report crew-managed hooks, warn on unmanaged/orphaned, verify symlink
  targets if symlink convention chosen.
- Guard: hooks are v3-only; no-op cleanly for v2 users.

## Acceptance criteria

- [ ] Hooks artifact class deployable + prunable without touching unmanaged hooks
- [ ] doctor reports hook health (managed/unmanaged/orphaned)
- [ ] Opt-in + env-gated; v2 no-op
- [ ] ADR recorded for the global-hook decision (managed manifest vs symlink)
