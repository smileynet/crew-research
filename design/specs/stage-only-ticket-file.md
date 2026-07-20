---
kind: constraint
id: stage-only-ticket-file
from_patterns:
  - "pattern:surgical-git-side-effects"
confidence: "★★"
protects_experience: "exp-safe-parallel-work"
user_story: "A claim made from a dirty tree commits exactly one file — your in-flight work never rides along."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "add -A|add \\.|add --all|commit -a|commit --all"
  include: ["*.py"]
  exclude: ["test_"]
  expect: absent
links:
  - target: "pattern:surgical-git-side-effects"
    type: constrains
---

# No Bulk Staging in tkt Source

## Rule

tkt source never invokes git add -A / add . / add --all / commit -a. Staging always takes one explicit path variable.

## Rationale

surgical-git-side-effects (operator D2a). R1 alternation check: each alternative is a git-flag literal unlikely in other contexts; test files excluded (fixtures may construct dirty trees).

## Violations Look Like

```python
run(["git", "add", "-A"])  # BAD: sweeps operator WIP into a claim commit
```

## Correct Usage

```python
run(["git", "add", "--", str(ticket_path)])  # GOOD: one explicit path
```
