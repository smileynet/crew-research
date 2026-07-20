---
kind: force
id: loud-parse-errors
polarity: constraint
hardness: hard
evidence_level: L2
source: "research:tk-capabilities"
serves: [pf-files-hand-editable, pf-consistent-agent-behavior]
---

# Loud Parse Errors

## Statement

A ticket file the tool cannot parse is a named hard error in every command — silent omission is forbidden.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `research:tk-capabilities`: "ticket SILENTLY OMITTED from ls/ready/blocked/query (exit 0, no warning)"
