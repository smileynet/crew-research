---
kind: force
id: structured-tool-output
polarity: constraint
hardness: soft
evidence_level: L1
source: "steering:project-conventions"
serves: [pf-consistent-agent-behavior, pf-plan-reflects-truth]
---

# Structured Tool Output

## Statement

Tool output follows the crew validation contract: structured JSON results and 0/1/2 exit codes.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `steering:project-conventions`: "Scripts and tools that produce output SHOULD return structured results: JSON {status: pass|fail|error} ... Exit code: 0=pass, 1=fail, 2=crash"
