---
kind: force
id: priority-jumps-order
polarity: constraint
hardness: hard
evidence_level: L1
source: "steering:frontier-work"
serves: [pf-urgency-out-of-band]
---

# Priority Jumps Order

## Statement

A priority: high flag must override lowest-number-first ordering in next-work selection.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `steering:frontier-work`: "unless a frontier ticket carries priority: high frontmatter (user-flagged), which jumps the number order"
