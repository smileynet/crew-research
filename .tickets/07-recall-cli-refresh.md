---
id: "07"
title: "Installed recall CLI matches repo source and docs"
status: open
blocked_by: []
spec: "project-review-followup"
---

# Installed recall CLI matches repo source and docs

## What to build

The recall CLI a user (or the steering) invokes has every command the documentation instructs (`import`, `search --type`, v3 session ingest). Install instructions lead to OUR tool, not the squatted PyPI package.

## Context

- **Relevant files:** `.memory/review-2026-07/tooling-audit.md` (diff evidence of missing commands)
- **Problem:** installed 0.1.0 predates repo source; `uv tool install recall` from PyPI installs an unrelated protobuf RPC package
- **Affected docs:** README.md, cheatsheet, user-setup-guide steering, tier extension install_hint

## Acceptance criteria

- [ ] `recall import --help` works on the installed CLI (reinstalled from repo source)
- [ ] Version bumped (source + `recall --version` agree, > 0.1.0)
- [ ] All install instructions point at the repo path (or a renamed unsquatted package): README, cheatsheet skill, user-setup-guide, tiers' install_hint
- [ ] recall spot check passes: `recall search` + `recall import` round-trip on a temp wing
- [ ] Decision recorded: keep spike/FINDINGS.md in place or promote to docs/development/ (scripts prunable)

## Out of scope

- New recall features
