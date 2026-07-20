---
kind: force
id: git-coordination-medium
polarity: constraint
hardness: hard
evidence_level: L2
source: "spec:ticket-cli-spec"
serves: [pf-concurrent-sessions-safe]
---

# Git Coordination Medium

## Statement

Claims, collisions, and WIP visibility resolve only through git (fetch/commit/push); any coordination story must run inside the target repo's git context.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `spec:ticket-cli-spec`: "Git is the coordination medium."
