---
kind: force
id: tool-name-no-shadow
polarity: constraint
hardness: soft
evidence_level: L2
source: "spec:ticket-cli-spec"
serves: [pf-consistent-agent-behavior]
---

# Tool Name No Shadow

## Statement

The CLI name must not shadow binaries already on operator machines (tk is installed and unrelated).

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `spec:ticket-cli-spec`: "Name tkt avoids shadowing the existing tk on PATH."
