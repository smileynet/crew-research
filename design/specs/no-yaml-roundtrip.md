---
kind: constraint
id: no-yaml-roundtrip
from_patterns:
  - "pattern:preserve-or-fail"
confidence: "★★"
protects_experience: "exp-trusted-files"
user_story: "A hand-edited ticket file is never re-quoted, re-ordered, or type-coerced by a tool rewrite."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "yaml\\.dump|yaml\\.safe_dump|yaml\\.round_trip_dump|ruamel"
  include: ["*.py"]
  exclude: ["test_"]
  expect: absent
links:
  - target: "pattern:preserve-or-fail"
    type: constrains
---

# No YAML Dumper on the Ticket Write Path

## Rule

tkt source never serializes ticket content through a YAML dumper (yaml.dump / safe_dump / ruamel round-trip). Ticket writes are line-surgical string edits.

## Rationale

preserve-or-fail: a dumper round-trip re-quotes ids (octal hazard), re-orders keys, coerces types, and destroys unknown-field formatting. R1 exclude analysis: test files may legitimately construct YAML fixtures, so they are excluded.

## Violations Look Like

```python
open(path, "w").write(yaml.dump(ticket))  # BAD: reorders, requotes, coerces
```

## Correct Usage

```python
lines[status_line_idx] = "status: " + new_status  # GOOD: surgical line edit
```
