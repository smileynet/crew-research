---
id: "47"
title: "tkt new prints 'claimed' but leaves status: open — align message with behavior"
status: done
blocked_by: []
---

# tkt new prints 'claimed' but leaves status: open — align message with behavior

Field report from the archwright lane (2026-07-22, archwright ticket 042/043 birth runs).

## Why

Observed output inconsistency between the two claim-adjacent commands:

- `tkt claim 042` → `claimed 042-tkt-native-adoption.md (in_progress pushed)` — frontmatter flips to `in_progress`. Matches the message.
- `tkt new coverage-modes-crash ...` → `claimed 043-coverage-modes-crash.md` — but frontmatter stays `status: open` and the ticket appears in `tkt ready` immediately.

The help text says `new` = "allocate + claim a new ticket", and the spec's R2 claim protocol uses "a pushed ticket is a claim" — so `new`'s "claimed" plausibly means the id-allocation claim (the push), not WIP. But the same word meaning two different things across adjacent commands invites the exact misread it caused: the operator filing a backlog bug via `tkt new` briefly believed they had marked it WIP.

## What to build

Pick one (spec owner's call — status vocabulary is frozen contract, so option 1 is the light touch):

1. **Wording fix:** `tkt new` prints `allocated NN-slug.md (pushed — id claimed, status: open)` or similar; reserve the bare word "claimed" for `in_progress` transitions.
2. **Behavior fix:** `tkt new` sets `in_progress` (making help text literal), with a `--no-claim` flag for filing backlog items. Heavier: changes the default shape of filed-not-worked tickets, and archwright's 043 birth run shows filing-without-working is a real use case.

Either way: one word = one meaning across `new`/`claim` output.

## Acceptance criteria

- [x] `tkt new` output cannot be read as an in_progress transition (wording or behavior aligned)
- [x] Help text for `new` matches what it actually does to `status`
- [x] R17 black-box coverage asserts the output line + resulting frontmatter status agree

## Out of scope

- Any status vocabulary change (frozen contract per ticket-cli-spec.md)

## Resolution (2026-07-23)

Option 1 (wording): new prints 'allocated NN (pushed — id claimed, status: open)'; bare 'claimed' reserved for claim; help text literal. Test: test_new_output_and_status_agree asserts output+frontmatter agreement. Commit df5e83d.
