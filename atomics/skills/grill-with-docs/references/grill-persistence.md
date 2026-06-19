# Grill Session Context Persistence

## Setup

At session start, create:
```
.scratch/grill-{topic-slug}/
├── INDEX.md
└── (question files added as session progresses)
```

## INDEX.md Format

```markdown
# Grill Session: {Topic}

**Date:** {ISO date}
**Plan/Feature:** {what's being grilled}
**Status:** in-progress | complete

## Questions

| # | Topic | Decision | File |
|---|-------|----------|------|
| 1 | {slug} | {one-line decision} | [Q01](Q01-{slug}.md) |
| 2 | {slug} | {one-line decision} | [Q02](Q02-{slug}.md) |

## Using These Findings

Reference individual question files when constructing:
- **PLAN.md** — decisions from Q01, Q03 inform phases
- **Specs** — requirements emerged from Q02, Q05
- **ADRs** — qualifying decisions identified in Q04, Q07
- **.memory/CONTEXT.md** — terms resolved throughout

Each Qnn file is self-contained context for the decision it covers.
```

## Question File Format (`Q{nn}-{slug}.md`)

```markdown
# Q{nn}: {Question text}

## Research

{Sources consulted, key findings, links}

## Options Considered

| Option | Pro | Con | Source |
|--------|-----|-----|--------|
| A | ... | ... | ... |
| B | ... | ... | ... |

## Decision

{What the user decided and why}

## Implications

{What this means for other decisions, constraints it creates}
```

## Workflow

1. Create `INDEX.md` when the grill session starts
2. After each question is answered and resolved:
   - Write `Q{nn}-{slug}.md` with the full context
   - Update the INDEX.md table with the new row
3. When referencing earlier decisions in later questions, cite the file: "per Q01 decision..."
4. At session end, update INDEX status to `complete`

## Why This Matters

- Grill sessions often run 10-20 questions across 30+ messages
- By question 15, the agent has lost context from question 3
- Persisted files survive context compaction and session restarts
- The INDEX links everything together for downstream consumers (plan, spec, ADR authoring)
