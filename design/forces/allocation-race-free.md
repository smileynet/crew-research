---
kind: force
id: allocation-race-free
polarity: constraint
hardness: hard
evidence_level: L2
source: "research:crew-ticket-needs; research:archwright-ticket-needs"
serves: [pf-concurrent-sessions-safe]
---

# Allocation Race Free

## Statement

Concurrent id allocation must not produce collisions; the allocation and the claim must be one indivisible step.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `research:crew-ticket-needs`: "ID allocation race — 3 collisions, one AFTER the claim protocol existed"
- `research:archwright-ticket-needs`: "id collision 009/010 → renumber commit 0806851 (per concurrent-sessions guard)"
