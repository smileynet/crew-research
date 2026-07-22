---
id: "46"
title: "tkt batch create under a spec (R13)"
status: open
blocked_by: []
spec: "ticket-cli"
---

# tkt batch create under a spec (R13)

## What to build

R13 (SHOULD): `tkt batch <slug:title> [<slug:title>...] --spec S [--blocked-by IDS]` —
allocate N sequential ids in one fetch-scan, create N files, ONE commit via
gitio.commit_files (staged-set verified), one push claiming the group; lost race
renumbers the whole group. Deferred from ticket 41: the group-renumber retry loop is
not trivial, and repeated `tkt new` is a documented-acceptable alternative
(.memory/specs/ticket-cli-spec.md R13; decision in ticket 41 Resolution).

## Acceptance criteria

- [ ] N tickets in one commit (staged set == created files), one push
- [ ] Lost-race group renumber black-box tested (R17, pre-receive hook fixture)
- [ ] Repeated-new equivalence: same corpus end-state as N tkt new calls
