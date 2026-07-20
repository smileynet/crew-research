---
kind: constraint
id: allocation-single-step
from_patterns:
  - "pattern:git-native-claim"
confidence: "★"
protects_experience: "exp-safe-parallel-work"
user_story: "An id the tool reports as allocated has actually landed on the remote — allocation and announcement cannot be separated."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "def cmd_new"
  include: ["*.py"]
  expect: present
links:
  - target: "pattern:git-native-claim"
    type: constrains
---

# Allocation Is a Single Owned Entry Point

## Rule

The `new` command exists as one implementation path (`def cmd_new`) — the only way tkt mints an id. Companion review criterion: its body performs fetch, scan, create, commit, push with no public seams that skip the push.

## Rationale

git-native-claim: allocation without announcement recreates the collision race. Grep proves the entry point exists (present); the sequence itself is verified by behavior spec claim-allocation-loop and the ticket-40 stale-local acceptance test.

## Violations Look Like

```python
def allocate_id(): ...  # separate from push: a mintable id with no claim
```

## Correct Usage

```python
def cmd_new(args):  # fetch -> scan -> create -> commit -> push, one path
```
