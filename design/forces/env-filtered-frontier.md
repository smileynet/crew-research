---
kind: force
id: env-filtered-frontier
polarity: constraint
hardness: hard
evidence_level: L2
source: "research:crew-ticket-needs"
serves: [pf-env-policy]
---

# Env Filtered Frontier

## Statement

Frontier computation must exclude tickets whose env designation does not match the current machine.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `research:crew-ticket-needs`: "env gating half-mechanical (nothing filters frontier by CREW_ENV)"
