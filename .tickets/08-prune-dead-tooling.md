---
id: "08"
title: "Dead and broken tooling is pruned or repaired"
status: done
blocked_by: []
spec: "project-review-followup"
---

# Dead and broken tooling is pruned or repaired

## What to build

Every tool in tools/ either works when invoked or doesn't exist. Orphaned artifacts are removed or wired in.

## Context

- **Relevant files:** `.memory/review-2026-07/tooling-audit.md ` (both reports), `.scratch/r2-r3-audit.md`

## Acceptance criteria

- [ ] okf-bundle: deleted (correcting recall-okf-integration spec line 96) OR wired into study-reference — decision recorded
- [ ] proofs: inspect-session.sh executable/invoked correctly so log_checks stop silently no-oping (11/15 definitions affected)
- [ ] proofs: adapters missing invoke.command_no_agent (agy/crush/closecode) fixed or documented as unsupported
- [ ] hooks/session-start-prime.json: deleted or wired into init.sh — decision recorded
- [ ] init.sh: empty PLUGIN comment block + dead --language flag removed
- [ ] session-analyzer: unused os import removed
- [ ] All remaining tools pass a smoke invocation

## Out of scope

- doctor/catalog (ticket 06), recall (ticket 07)
