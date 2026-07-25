---
id: "50"
title: "tkt close --ac N,N: enumerated AC box-checking (blanket --check-acs rejected)"
status: open
blocked_by: []
env: either
spec: "ticket-cli"
---

# tkt close --ac N,N: enumerated AC box-checking (blanket --check-acs rejected)

## What to build

`tkt close <id> --ac 1,3,4` (and `tkt edit <id> --ac ...`) — check the ENUMERATED
acceptance boxes (1-based, in file order) as part of the close/edit. Out-of-range
indices are a hard error before any write (R18 pattern).

**Condition (the design constraint that makes this acceptable):** enumeration is
mandatory — there is deliberately NO `--check-acs`/`--all` variant. Blanket flipping
was REJECTED (guidance-sync 2026-07-25): the manual flip is the moment AC claims get
audited; a bulk flag invites rubber-stamping — the exact anti-pattern the 2026-07-22
ticket-normalization guarded against (subagents were explicitly instructed "no blind
box-checking"). Forcing the caller to name each box preserves the audit moment while
killing the repeated python one-liner (5× in the 2026-07-25 goal session).

## Context

- **Origin:** guidance-sync P4 finding 2026-07-25 — the box-flip snippet repeated 5×
  across closes in one session; operator asked for a ticket with a condition instead
  of a blanket flag
- **Files:** `tools/tkt/tkt/cli.py` (cmd_close, cmd_edit, UNCHECKED_AC regex),
  `tools/tkt/tests/`
- **Interaction with close warning:** boxes checked via `--ac` count toward the
  unchecked-ACs warning computation (flip first, then warn on the remainder)

## Acceptance criteria

- [ ] `tkt close <id> --ac 1,3` flips exactly boxes 1 and 3 (file order), then closes;
      remaining unchecked boxes still trigger the warning
- [ ] `tkt edit <id> --ac 2` flips box 2 without a status change
- [ ] Out-of-range or non-numeric index = hard error, no file modification
- [ ] No blanket variant exists; help text states enumeration is deliberate (link the
      rejection rationale)
- [ ] Byte-preservation: only the named checkbox lines change (existing test pattern)
- [ ] Suite extended; `mise run test:tkt` green

## Out of scope

- Any `--all`/`--check-acs` bulk flag (rejected, see above)
- AC text editing (this is check-state only)
