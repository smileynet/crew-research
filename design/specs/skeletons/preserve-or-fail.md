---
kind: constraint
id: skeleton-preserve-or-fail
from_patterns:
  - "pattern:preserve-or-fail"
confidence: "—"
protects_experience: "pf-files-hand-editable"
user_story: "A hand-edited ticket file is never mangled: tkt writes never round-trip ticket files through a YAML dumper."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "yaml\\.dump|yaml\\.safe_dump|\\.dump\\("
  include: ["*.py"]
  expect: absent
links:
  - target: "pattern:preserve-or-fail"
    type: constrains
---

# Skeleton: No YAML Dumper Writes Ticket Files

## Rule

tkt source never serializes ticket files via a YAML dumper — edits are line-surgical.

## Rationale

Primary invariant of preserve-or-fail: a dumper round-trip re-quotes, re-orders, coerces types (octal ids), and drops unknown-field formatting. Activates when tools/tkt lands.
