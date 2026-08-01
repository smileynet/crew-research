# Review Marker Schema

The marker is a coverage ledger, not proof that reviewed work is correct.

## Invariants

- Store project state at `.codex/review-marker.json`.
- Treat `reviewed_through` as an inclusive, ancestry-closed boundary.
- Pin `adoption.target` once; never absorb later commits silently.
- Derive ticket blobs from the pinned tree, never the working tree.
- Store ticket path plus blob and record only completed batch coverage.
- Leave coverage unchanged while scope or ancestry remains unresolved.

## Adoption States

- `not_started`: no history is claimed as reviewed.
- `in_progress`: target is pinned and one or more batches may be complete.
- `complete`: all target commits and ticket blobs were reviewed.
- `skipped`: the user explicitly chose and recorded a trusted baseline.

During adoption, `reviewed_ticket_blobs` contains only completed target ticket pairs. At completion, replace `tickets` with the full target snapshot and clear progress entries.

## Commit Batches

Choose checkpoints from `git rev-list --first-parent --reverse <target>`. Measure each reachable delta with `git rev-list --count <boundary>..<checkpoint>`. For the first batch, include every root reachable through the checkpoint.

Never advance until the checkpoint's complete reachable delta is reviewed. Treat an oversized merge as one checkpoint even if its analysis is split internally.

## Ticket Batches

Inventory every ticket at the pinned target. Review pairs absent from `reviewed_ticket_blobs`, then append them. Review open tickets for scope and consistency; also review done tickets against implementation and acceptance criteria.

For `tkt`, use query for metadata, validate for contract findings, and Git for identity. Fall back to tree enumeration on parser failure and disclose reduced semantic validation. Never use `tkt ready` as scope.

## Completion

Complete adoption only when the boundary equals the target, every target ticket pair was reviewed, and no coverage gap remains. Set both coverage flags, populate the normal ticket snapshot, preserve `completed_at`, and defer newer commits to the next incremental review.

## Schema 1 Migration

- Non-null boundary: migrate as complete without expanding historical claims.
- Null boundary: migrate as not started.
- Never infer coverage from marker existence.

## Failures

- Fetch shallow history before diagnosing a missing object.
- Stop on a non-ancestor boundary; offer full adoption or explicit recovery.
- Keep dirty state outside committed coverage.
- Review deletion once, then omit it from the completed snapshot.
- Treat renames as old-path deletion plus new-path addition.
