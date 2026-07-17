---
id: "18"
title: "Explore: concurrent-session ticket allocation guard in frontier-work steering"
status: open
blocked_by: []
spec: "field-feedback"
---

# Explore: ticket-ID allocation guard for concurrent sessions

Feature suggestion from an archwright working session (2026-07-17) where two
concurrent sessions on the same repo both allocated ticket 005 (different
filenames, overlapping scope — both independently implemented the same feature),
requiring a mid-merge reconciliation of code, docs, and duplicate tickets.

## Observed failure mode

`frontier-work.md` covers picking and closing tickets but not CREATING them.
With 2+ sessions active on one repo, ticket creation is a race: both sessions
scanned local `.tickets/`, saw the same max ID, and claimed it. Worse than the ID
collision: the ticket content overlapped, so both sessions built the feature.

## Suggested exploration

Would frontier-work steering benefit from a "Creating Tickets" section, e.g.:

- `git fetch` + rescan remote `.tickets/` immediately BEFORE allocating an ID
- Commit + push the ticket file promptly after creation — a pushed ticket is a
  claim; an unpushed ticket is invisible to other sessions
- Optional `lane:` frontmatter when sessions have declared work lanes, so a
  session can tell at a glance whether a ticket is theirs to work
- On discovering a collision: reconcile immediately (merge content into the
  lower-numbered/pushed ticket, delete the duplicate) rather than letting both
  proceed

## Evidence

- archwright repo 2026-07-17: `005-include-globs.md` vs `005-grep-include-globs.md`,
  both implemented `include:` globs for the check tool; reconciliation merge
  `06d74a2` unioned the two implementations
- Cost: ~30 min of merge-conflict resolution + duplicated implementation effort;
  benefit of the collision (two designs to union) was accidental, not free
