---
kind: constraint
id: skeleton-layered-selection
from_patterns:
  - "pattern:layered-selection"
confidence: "—"
protects_experience: "pf-urgency-out-of-band"
user_story: "Selection is a fixed pipeline: env filter, then priority jump, then ascending id — never a weighted score."
check:
  method: grep
  target: "tools/tkt"
  pattern: "weight|score"
  include: ["*.py"]
  expect: absent
links:
  - target: "pattern:layered-selection"
    type: constrains
---

# Skeleton: No Scoring in Frontier Selection

## Rule

tkt selection code contains no weighted scoring — only the three-stage filter/jump/order pipeline.

## Rationale

Primary invariant of layered-selection: predictable staged precedence, weights rejected at resolve. Activates when tools/tkt lands.
