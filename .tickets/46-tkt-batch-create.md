---
id: "46"
title: "tkt batch create under a spec (R13)"
status: done
blocked_by: []
env: either
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

- [x] N tickets in one commit (staged set == created files), one push
- [x] Lost-race group renumber black-box tested (R17, pre-receive hook fixture)
- [x] Repeated-new equivalence: same corpus end-state as N tkt new calls

## Resolution (2026-07-25)

cmd_batch shipped: N sequential ids from one fetch-scan, N files in ONE commit via gitio.commit_files (staged-set verified: diff-tree == created files asserted in test), one push; lost race renumbers the WHOLE group (black-box: pre-receive hook snipe -> group 42,43 renumbered to 43,44, still one commit, corpus validates). Repeated-new equivalence: frontmatter field-for-field identical modulo id/title. Suite 51 passed; 12 static design checks pass. Output follows ticket-47 wording (allocated..., status: open).
