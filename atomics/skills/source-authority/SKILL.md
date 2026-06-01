---
name: source-authority
description: "Source authority hierarchy, citation tags, and conflict resolution for all factual claims. Always active — governs how sources are ranked, cited, and resolved across all task types."
metadata:
  type: steering
  invocation: passive
  practice: null
---

# Source Authority

## Hierarchy (higher level wins)

| # | Category | Answers | 1st-party example | 3rd-party example |
|---|----------|---------|-------------------|-------------------|
| 1 | **Observable artifact** | What IS | Running code, test output, hex dump, manuscript | Measured data, binary behavior, recorded footage |
| 2 | **Governing specification** | What SHOULD be | API contract, world bible, style guide | Language spec, RFC, W3C standard |
| 3 | **Rationale record** | WHY | ADRs, design notes, author commentary | PEPs, errata, developer interviews |
| 4 | **Authoritative reference** | Domain knowledge | Project docs, internal wiki | Official docs, peer-reviewed papers |
| 5 | **Informed commentary** | Expert opinion | Team discussion, playtest notes | Conference talks, expert blogs |
| 6 | **Community knowledge** | General signal | Personal notes, scratch files | Stack Overflow, forums, fan wikis |

## Conflict Resolution

1. Same level → 1st-party wins
2. Same level, same party → most recent wins
3. Cross-level → higher level wins; note the conflict
4. Level 1 vs Level 2 (IS vs SHOULD) → flag the gap — it's a bug, a spec update, or a documented divergence

## Source Tags (use when citing)

Format: `[L{n}:{confidence}]`

```
- [L4:verified] [Redis Persistence](https://redis.io/docs/...) — official docs, confirmed for v7.2
- [L6:reported] [SO: workaround](https://stackoverflow.com/...) — single answer, untested
- [L1:verified] `cargo test` output — 47 passed, 0 failed
```

## Confidence Labels

| Label | Meaning |
|-------|---------|
| **Verified** | Directly observed/tested. Cite evidence. |
| **Established** | Multiple authoritative sources agree. Cite them. |
| **Reported** | Single credible source. Name it. |
| **Inferred** | Reasoning from evidence. State the reasoning. |
| **Tentative** | Plausible but unconfirmed. Flag explicitly. |

## Citation Rules

- Cite the source, not just the claim
- No citing without reading — a link ≠ the relevant passage
- Separate observation from interpretation
- When sources conflict, surface BOTH with levels before resolving
- Never present speculation as fact — use confidence labels
