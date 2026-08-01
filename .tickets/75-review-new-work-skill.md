---
id: "75"
title: "Add resumable full-history review adoption skill"
status: done
blocked_by: []
---

# Add resumable full-history review adoption skill

## What to build

Create a global `review-new-work` atomic skill that maintains a repository-local
Codex review marker. When no marker exists, default to reviewing all reachable
history and file-based tickets through a pinned target. Split large histories
into resumable, ancestry-closed commit batches and resumable ticket batches.

Include `tkt` validation/query support with Git-tree fallback. Keep review
quality in the existing `code-review` protocol. Deploy the skill in basic and
full tiers and add activation plus effectiveness evals.

## Acceptance criteria

- [x] Missing marker starts full-history adoption without first asking to skip history
- [x] Adoption pins a target and defers newer commits
- [x] Commit checkpoints cover complete ancestry; partial merge ancestry never advances
- [x] Ticket batches resume by committed path/blob without claiming unread tickets
- [x] Completed adoption transitions to normal incremental review
- [x] `tkt` validation/query and Git-tree fallback are documented
- [x] Skill is under 100 lines with explicit scope and progressive references
- [x] Basic and full tiers include the skill
- [x] Activation and effectiveness evals cover adoption, resumption, and false triggers
- [x] Composition, lint, eval, generation, and deployment checks pass

## Resolution (2026-08-01)

Added the resumable full-history review adoption atomic, schema-v2 marker template, tier integration, activation/effectiveness definitions, and validated live adoption/resume behavior.
