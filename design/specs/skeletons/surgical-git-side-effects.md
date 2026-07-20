---
kind: constraint
id: skeleton-surgical-git-side-effects
from_patterns:
  - "pattern:surgical-git-side-effects"
confidence: "—"
protects_experience: "pf-concurrent-sessions-safe"
user_story: "A claim or close commit made from a dirty tree contains exactly one file: the ticket."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "git add -A|git add \\.|commit -a"
  include: ["*.py"]
  expect: absent
links:
  - target: "pattern:surgical-git-side-effects"
    type: constrains
---

# Skeleton: No Bulk Staging in tkt Source

## Rule

tkt source never uses git add -A, git add ., or commit -a — staging is explicit single-path.

## Rationale

Primary invariant of surgical-git-side-effects (operator decision D2a). Activates when tools/tkt lands.
