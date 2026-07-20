---
kind: force
id: sequential-readable-ids
polarity: constraint
hardness: hard
evidence_level: L2
source: "spec:ticket-cli-spec"
serves: [pf-tickets-as-history, pf-consistent-agent-behavior]
---

# Sequential Readable Ids

## Statement

Sequential human-readable NN[-N]-slug ids are entrenched: cross-referenced in prose and load-bearing for lowest-number-first selection.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `spec:ticket-cli-spec`: "Random IDs (tk's t-xxxx) break existing cross-references and the lowest-number-first selection rule."
