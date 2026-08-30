---
id: "141"
title: "Wire mise tasks + verify cross-platform + update docs for known-tools orchestration"
status: done
blocked_by: ["138", "139", "140"]
---

# Wire mise tasks + verify cross-platform + update docs for known-tools orchestration

## What to build

TBD

## Acceptance criteria

- [x] TBD

## Resolution (2026-08-30)

Wired 3 mise tasks (tools:deploy/doctor/telemetry, raw=true, invoke known-tools.sh). Verified: mise tasks lists all 3; mise run tools:doctor runs end-to-end (recall+tkt health, Errors:0). Docs updated: AGENTS.md (layout consumer line + Commands block w/ CREW_TOOLS_ROOT note), user-setup-guide.md (orchestration subsection: 3 tasks, per-OS build leg, repo probe order, skip-not-fail). Fixed CR artifact in doctor summary. generate.sh validate passes (21 files).
