---
kind: force
id: body-is-prose
polarity: constraint
hardness: hard
evidence_level: L2
source: "spec:ticket-cli-spec"
serves: [pf-tickets-as-history, pf-files-hand-editable]
---

# Body Is Prose

## Statement

The ticket body is a human/agent-authored spec; the tool manages frontmatter and may only append (dated stubs), never restructure prose.

## Who Feels It

the world (platform limits, prior decisions)

## Evidence

- `spec:ticket-cli-spec`: "the body is the spec (tool never manages prose)"
