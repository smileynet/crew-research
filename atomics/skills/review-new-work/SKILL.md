---
name: review-new-work
description: "Incremental and full-history repository review with resumable adoption batches. Use when reviewing new work, initializing review tracking, reviewing all work to date, resuming historical review, inspecting unreviewed commits, or reviewing changed tickets. Trigger: review new work, adopt repository, review all history, resume review, review marker, unreviewed commits."
metadata:
  type: protocol
  invocation: both
  practice: null
---

# Review New Work

Review committed work without modifying implementation. Findings become one
confirm-first ticket, not inline fixes.

## Establish Scope

1. Read project instructions; capture `SESSION_HEAD = git rev-parse HEAD` and dirty state.
   Use the caller's `RUN_ID`, or generate a unique one when invoked directly.
2. Read `.codex/review-marker.json` and [references/marker-schema.md](references/marker-schema.md).
3. Choose the workflow:
   - Missing marker or `adoption.status = not_started`: start adoption.
   - `adoption.status = in_progress`: resume its pinned target.
   - Completed adoption: review `reviewed_through..SESSION_HEAD` incrementally.
4. Validate boundaries as available ancestors. Fetch shallow history before diagnosing a rewrite; stop on unrelated history.
5. Ignore a marker commit only when its diff changes exactly `.codex/review-marker.json`.

## Adopt the Repository

Prefer complete history. Use a trusted baseline only when the user explicitly chooses to skip review.

1. Copy [references/review-marker.json](references/review-marker.json) into the project when needed.
2. Pin `adoption.target` once; defer newer commits.
3. Inventory all target commits and ticket path/blob pairs.
4. Review in one pass when manageable; otherwise default to 25 commits and 15 tickets.
5. Use ancestry-closed checkpoints from the target's first-parent chain. Review a merge's complete reachable delta before advancing, even when it exceeds the limit.
6. Resume tickets by target path/blob; never record unread versions.
7. Persist each complete batch with `adoption.status = in_progress`, verdict, and remaining coverage.
8. Complete adoption only after all target commits and tickets are covered; then process deferred commits incrementally.

## Discover Tickets

Follow project instructions; default to committed `.tickets/**/*.md` files.

For `tkt`, run version, validate, and query. Read validation JSON on exit 1 and each selected ticket file completely. If query fails, report it and enumerate the pinned Git tree. Never use `tkt ready` as review scope or run ticket-mutating commands during review.

Compare committed path/blob pairs for new, changed, deleted, or renamed tickets. Review newly done tickets against every acceptance criterion and resolution.

## Review and Checkpoint

1. Review **Standards**: correctness, security, maintainability, portability, tests, and conventions.
2. Review **Spec**: ticket requirements, acceptance criteria, scope, evidence, and closure validity.
3. Run project verification and read its output.
4. Report severity-ranked findings, verdict, completed coverage, and remaining coverage.
5. When actionable findings exist, create exactly one aggregate ticket from
   [references/review-findings-ticket.md](references/review-findings-ticket.md). Use `tkt new ... --priority high`
   when available. Preserve the supplied review run id, identify Codex as reporter,
   and require independent confirmation. Populate the allocated file after `tkt new`,
   then commit and push that content before claiming success.
6. When no actionable findings exist, create no ticket and return an explicit clean result.
7. Recheck session head. During adoption, allow newer commits only when the pinned target is unchanged and report them as deferred.
8. Advance after a complete batch even when changes are requested; coverage is not approval.
9. Never advance partial ancestry or unread ticket blobs. Derive blobs from the pinned tree and validate JSON.
10. Commit and push the marker separately only when project instructions authorize it.
11. End with the [Codex review result contract](../dispatch-codex-review/references/result-contract.md),
    using the caller's run id and target.

## Scope

Does NOT cover applying fixes, choosing frontier work, dispatching Codex, or
reviewing one arbitrary diff. Ticket creation is limited to the aggregate review
result. Use code-review for review quality and frontier-work for implementation.
