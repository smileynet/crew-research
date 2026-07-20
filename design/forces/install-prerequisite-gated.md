---
kind: force
id: install-prerequisite-gated
polarity: constraint
hardness: soft
evidence_level: L1
source: "adr:0008"
serves: [pf-consistent-agent-behavior]
---

# Install Prerequisite Gated

## Statement

Crew extensions auto-deploy only when their external prerequisite is on PATH; anything else is a documented manual install.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `adr:0008`: "extensions are declared inside tier manifests and auto-deploy when their prerequisite is met"
