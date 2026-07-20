---
kind: constraint
id: skeleton-automate-or-drop
from_patterns:
  - "pattern:automate-or-drop"
confidence: "—"
protects_experience: "pf-tickets-as-history"
user_story: "tkt validate reports unchecked acceptance boxes on done tickets, so ceremony decay is visible instead of silent."
check:
  method: grep
  target: "tools/tkt"
  target_status: pending
  pattern: "unchecked|checkbox|- \\[ \\]"
  include: ["*.py"]
  expect: present
links:
  - target: "pattern:automate-or-drop"
    type: constrains
---

# Skeleton: Validate Detects AC Decay

## Rule

tkt validate implementation contains the unchecked-ACs-on-done detection.

## Rationale

Primary invariant of automate-or-drop: hand-set fields get a mechanical watcher. Activates when tools/tkt lands.
