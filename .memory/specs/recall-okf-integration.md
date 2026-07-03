# How Recall + OKF Fit Together

## The Three-Layer Model

```
Behavior (skills/)     → What to DO      → SKILL.md format
Memory (recall)        → What WAS        → SQLite + vectors (MemPalace-inspired)
Knowledge (.memory/)   → What IS         → Markdown files (OKF-informed)
```

These layers serve different purposes and have different lifecycles:

| Layer | Changes when | Accessed by | Format driver |
|-------|-------------|-------------|---------------|
| Behavior | Skills are authored/improved | Agent (on-demand activation) | Activation triggers in description |
| Memory | Sessions happen, decisions are made | Agent (recall search/prime) | Semantic similarity + BM25 |
| Knowledge | Terms resolve, designs settle, specs solidify | Agent (file reads) + humans | File path + progressive load |

## Recall = MemPalace Concepts, Purpose-Built

We adapted MemPalace's conceptual model:

| MemPalace | Our recall | Why we kept it |
|-----------|-----------|---------------|
| Wings | Wings | Project scoping works — sessions belong to projects |
| Rooms | Rooms | Topic classification helps filter search results |
| Drawers | Drawers (chunks) | Verbatim storage + chunking beats summarization for recall accuracy |
| Palace init | `recall ingest` | One-time import of existing history |
| `wake-up` | `recall prime` | Session-start context injection |
| `mine` | `recall ingest` | Batch import of session transcripts |
| MCP server (35 tools) | Shell CLI (5 commands) | We don't need MCP — shell calls are cheaper in tokens |
| ChromaDB + pgvector | SQLite + exact cosine | <50K vectors don't need approximate search |

What we intentionally left out:
- Knowledge graph (temporal entity-relationships) — overkill for our scale
- Agent diaries — our handoff skill covers this
- Auto-save hooks — kiro-cli's agentSpawn hook handles session-start; ingestion is batch
- Spellcheck/extract extras — not needed for conversation retrieval

## What OKF Informs

OKF doesn't replace anything we have. It clarifies the mental model and offers a future integration path:

### For .memory/ (Knowledge Layer)

OKF's core insight: **knowledge is nouns, not verbs.** A glossary entry, an ADR, a spec — these describe what EXISTS. They're not instructions for how to behave.

This validates our separation:
- `.memory/` = knowledge (what IS) — could conform to OKF
- `skills/` = behavior (what to DO) — cannot be OKF, different purpose entirely

OKF's minimal spec (only `type` required, everything else optional) maps cleanly:

| .memory/ content | OKF type | Already has frontmatter? |
|-----------------|----------|:------------------------:|
| CONTEXT.md | `glossary` | No |
| ADRs | `adr` | No |
| Specs | `spec` | No (1 has partial) |
| Session reviews | `review` | Yes (no `type`) |

If/when we conform: add `type` field to frontmatter. That's the only required change.

### For recall (Memory Layer)

OKF could expand what recall searches over:

**Current**: recall ingests session transcripts (JSONL) only.

**With OKF import**: recall could also ingest:
- `.memory/` files as searchable knowledge (type-tagged)
- External OKF bundles from other teams/projects
- Reference repo bundles (we already generate these via `tools/okf-bundle/`)

This means `recall search "deployment architecture"` could return:
1. A past conversation where you discussed it (session memory)
2. The relevant ADR that captured the decision (knowledge)
3. A pattern from a reference repo bundle (external knowledge)

All in one search, ranked by relevance.

### For skill references/ (Behavior Layer support)

Skill `references/` dirs are progressive-load knowledge that supports behavior. They sit at the boundary:
- They're loaded by the behavior system (on-demand, when skill activates)
- But their content IS knowledge (vocabulary, templates, checklists)

OKF's `index.md` pattern matches our progressive-load pattern exactly. If references/ gained minimal OKF frontmatter (`type`), recall could index them too — making skill reference knowledge findable via search without the skill being active.

## Integration Roadmap (evidence-first, per Codex review)

1. **Now**: recall stays session-only. .memory/ stays as-is. No premature changes.
2. **Next**: implement `recall import <path>` for markdown ingestion (enables OKF consumption).
3. **Then**: run retrieval evals — does adding .memory/ to recall's index improve agent answers?
4. **If yes**: add minimal `type` frontmatter to .memory/ files where evals show value.
5. **If OKF gains traction**: emit .memory/ as a consumable OKF bundle for external tools.

The key principle: **don't conform for conformance's sake.** Conform only where measurement shows retrieval or agent behavior improvement.
