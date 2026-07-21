---
kind: constraint
id: loud-parse-errors
from_patterns:
  - "pattern:preserve-or-fail"
confidence: "★"
protects_experience: "exp-trusted-files"
user_story: "A broken ticket file is a named error in every command, never a silently missing row."
check:
  method: grep
  target: "tools/tkt"
  pattern: "class TicketParseError"
  include: ["*.py"]
  expect: present
links:
  - target: "pattern:preserve-or-fail"
    type: constrains
---

# Named Parse Error Type Exists and Is Raised

## Rule

tkt defines a dedicated TicketParseError (carrying the filename) that parse failures raise. Companion review criterion: no command catches it to skip a file — only to abort with the message.

## Rationale

preserve-or-fail: the tk silent-omission anti-pattern (exit 0, ticket invisible). A named exception type makes the loud path structural; presence is greppable, and the no-swallow half is reviewed + tested (ticket 40 AC: unparseable fixture fails loudly in every command).

## Violations Look Like

```python
except Exception:
    continue  # BAD: ticket vanishes from listings
```

## Correct Usage

```python
raise TicketParseError(path, "duplicate key: status")  # GOOD: named, loud
```
