---
kind: force
id: ids-as-text
polarity: constraint
hardness: hard
evidence_level: L2
source: "spec:ticket-cli-spec"
serves: [pf-files-hand-editable]
---

# Ids As Text

## Statement

Ticket ids must be read and written as raw text, never as YAML-typed scalars.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `spec:ticket-cli-spec`: "Archwright's are unquoted (id: 010) — YAML 1.1 would parse octal."
