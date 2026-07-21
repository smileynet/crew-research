---
kind: constraint
id: skeleton-git-native-claim
from_patterns:
  - "pattern:git-native-claim"
confidence: "—"
protects_experience: "pf-concurrent-sessions-safe"
user_story: "A new ticket id allocated on one machine never collides with another machine, because allocation and push-claim are one command."
check:
  method: grep
  target: "tools/tkt"
  pattern: "def cmd_new|def new_command|class NewCommand"
  include: ["*.py"]
  expect: present
links:
  - target: "pattern:git-native-claim"
    type: constrains
---

# Skeleton: Allocation Entry Point Exists in tkt Source

## Rule

tkt source contains the `new` command implementation (the single mint-to-announce entry point).

## Rationale

Primary invariant of git-native-claim: allocation is one owned command, not scattered steps. Activates when tools/tkt lands (ticket 40).
