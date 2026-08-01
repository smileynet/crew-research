---
id: "78"
title: "Dispatch Codex reviews into confirm-first high-priority tickets"
status: in_progress
blocked_by: []
priority: high
---

# Dispatch Codex reviews into confirm-first high-priority tickets

## What to build

Streamline independent review by making `review-new-work` file and push one
high-priority aggregate ticket when it finds actionable issues. The ticket must
identify Codex as reporter, correlate to a unique review run, and require the
implementing agent to confirm or reject every finding before changing code.

Add a focused `dispatch-codex-review` orchestration skill that pins the target,
dispatches Codex, then fetches and verifies either the correlated findings
ticket or an explicit clean result. Update frontier work to enforce the
confirm-first contract when consuming these tickets.

## Acceptance criteria

- [x] Review findings produce one pushed `priority: high` aggregate ticket
- [x] Ticket records Codex provenance, run id, target, coverage, and unconfirmed status
- [x] Ticket requires independent confirmation or rejection of every finding
- [x] Clean reviews create no ticket and return an explicit correlated clean result
- [x] Dispatcher correlates by run id rather than newest-ticket ordering
- [x] Dispatcher fails closed on missing, duplicate, local-only, or mismatched results
- [x] Frontier work confirms Codex findings before implementation
- [x] New skill is focused, under 100 lines, and included in basic and full tiers
- [x] Activation and workflow evals cover ticketed, clean, concurrent, and ambiguous outcomes
- [x] Live skills are updated and the end-to-end contract is forward-tested
