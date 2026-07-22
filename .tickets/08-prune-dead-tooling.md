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

- [x] okf-bundle: deleted (correcting recall-okf-integration spec line 96) OR wired into study-reference — decision recorded
- [x] proofs: inspect-session.sh executable/invoked correctly so log_checks stop silently no-oping (11/15 definitions affected)
- [x] proofs: adapters missing invoke.command_no_agent (agy/crush/closecode) fixed or documented as unsupported
- [x] hooks/session-start-prime.json: deleted or wired into init.sh — decision recorded
- [x] init.sh: empty PLUGIN comment block + dead --language flag removed
- [x] session-analyzer: unused os import removed
- [x] All remaining tools pass a smoke invocation

## Out of scope

- doctor/catalog (ticket 06), recall (ticket 07)

## Resolution
**Closed:** 2026-07-17 (Resolution backfilled 2026-07-22). Dead tooling pruned and silent no-ops repaired: okf-bundle and session-start-prime hook deleted with decisions recorded, inspect-session.sh exec bit fixed, proofs run.sh skips null adapters (agy/crush/closecode annotated unsupported), init.sh dead code and parse.py unused import removed, all remaining tools smoke-invoked clean. Evidence: docs/plan.md ticket-table row 08; closing commit 24d9691 (commit body verifies each criterion incl. smoke invocations).
