---
id: "07"
title: "Installed recall CLI matches repo source and docs"
status: done
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

- [x] `recall import --help` works on the installed CLI (reinstalled from repo source)
- [x] Version bumped (source + `recall --version` agree, > 0.1.0)
- [x] All install instructions point at the repo path (or a renamed unsquatted package): README, cheatsheet skill, user-setup-guide, tiers' install_hint
- [x] recall spot check passes: `recall search` + `recall import` round-trip on a temp wing
- [x] Decision recorded: keep spike/FINDINGS.md in place or promote to docs/development/ (scripts prunable)

## Out of scope

- New recall features

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). Recall CLI reinstalled from repo source at 0.2.0, import+search round-trip verified on a temp wing, all install docs (README, cheatsheet, cli-reference, both tier install_hints, user-setup-guide) point at ./tools/recall with squatted-PyPI warning, spike findings promoted to docs/development/. Evidence: docs/plan.md ticket-table row 07; closing commit 1af6756 (commit body verifies each criterion).
