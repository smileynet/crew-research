---
kind: constraint
id: validate-reports-decay
from_patterns:
  - "pattern:automate-or-drop"
confidence: "★"
protects_experience: "exp-history-trustworthy"
user_story: "Ceremony decay (unchecked boxes on done tickets, dangling deps) is reported by validate, not discovered during archaeology."
check:
  method: grep
  target: "tools/tkt"
  pattern: "unchecked-acs-on-done|dangling-blocked-by"
  include: ["*.py"]
  expect: present
links:
  - target: "pattern:automate-or-drop"
    type: constrains
---

# Validate Implements the Decay Findings

## Rule

The validate implementation contains the two observed decay-class findings as named rules: unchecked-acs-on-done and dangling-blocked-by (rule ids from contract cli-outputs).

## Rationale

automate-or-drop: hand-set fields need a mechanical watcher. The finding rule-ids are part of the cli-outputs contract, so their literals appearing in source is a faithful presence check.

## Violations Look Like

(validate exists but only checks parse errors — decay classes unwatched)

## Correct Usage

```python
Finding(file=f, rule="unchecked-acs-on-done", severity="warning")
```
