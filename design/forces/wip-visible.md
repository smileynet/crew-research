---
kind: force
id: wip-visible
polarity: constraint
hardness: soft
evidence_level: L2
source: "research:archwright-ticket-needs"
serves: [pf-concurrent-sessions-safe]
---

# Wip Visible

## Statement

Work-in-progress must be visible to concurrent sessions in the pushed ticket state, not only in commit messages.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `research:archwright-ticket-needs`: "ticket 005 implemented independently by two concurrent sessions same day → reconciliation merge"
