---
name: grill-with-docs
description: "Design interrogation with evidence-backed recommendations. Researches each question via web search before presenting options. Updates CONTEXT.md and offers ADRs inline. Dispatches spikes for empirical validation."
metadata:
  type: process
  invocation: user-only
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Ask one question at a time. Wait for my answer before continuing.

**Self-answer gate (mandatory):** Before asking ANY question, check: can the codebase, docs, or a web search answer this? If yes, explore and state what you found — do not ask. Only ask when the answer requires user intent, preference, or constraints not discoverable from available sources.

**Before presenting each question, research it.** Do not rely on general knowledge alone.

## Research Protocol

For each genuine design question, research BEFORE presenting:

### What to research

1. **Library/tool documentation** — how does the technology handle this? What's documented/supported? (web search → fetch docs)
2. **Prior art** — how did other projects solve this? What patterns exist?
3. **Anti-patterns** — what do maintainers warn against? (issues, post-mortems)
4. **Ecosystem health** — actively maintained? Known issues?

### How to classify options

Score each option along:
- **Supported vs. incidental** — documented feature or undocumented side effect?
- **Scoped vs. global** — affects only this subsystem, or the whole architecture?
- **Reversible vs. sticky** — how easy to change later?
- **Portable vs. environment-specific** — works everywhere, or only specific OS/tooling?

### Research gates (mandatory before presenting options)

| # | Gate | Fail action |
|---|------|-------------|
| G1 | Found relevant docs/examples for this technology | Search `"{technology} {concept} docs"` |
| G2 | Searched for WARNINGS against this approach | Search `"{technology} {approach} problems"` or `"deprecated"` or `"migration"` |
| G3 | Found 2+ independent sources before recommending | Search more broadly; if only 1 source, label "unconfirmed" |

Do NOT present options until all 3 gates pass. G2 findings MUST appear in the Con column with source.

### How to present

| Option | Pro | Con | Source |
|--------|-----|-----|--------|
| A | ... | ... | docs.rs/crate: "feature X is supported..." |
| B | ... | ... | Anti-pattern per maintainer: github.com/... |

State confidence: High (documented) / Medium (works but undocumented) / Low (inferred from source)

### When to skip research

- The question is about internal project conventions (just read the codebase)
- The answer is in existing project docs or decision records
- The question is answerable from docs you already fetched

## Spike Dispatch

When a question requires empirical validation (not answerable by docs/research alone):

**Subagent spike** (answerable in minutes): dispatch a subagent with the question, method, and expected return format. Incorporate results immediately.

**Prototype dispatch** (needs its own session/context budget): see [references/prototype-dispatch.md](references/prototype-dispatch.md) for the full handoff template.

## Domain Awareness

Look for existing documentation:
- `.memory/CONTEXT.md` — domain glossary
- `.memory/adr/` — architectural decision records
- `docs/` — project documentation
- `.references/` — reference repos

## During the Session

### Maintain CONTEXT.md

- If `.memory/CONTEXT.md` doesn't exist, create it on first term resolution
- When a term is resolved or clarified, update CONTEXT.md immediately — don't batch
- Format: `**Term**: Definition. _Avoid_: synonym.`
- CONTEXT.md is a glossary ONLY — no implementation details, no specs, no scratch notes

### Challenge against the glossary

When the user uses a term that conflicts with CONTEXT.md, call it out.

### Challenge against existing decisions

Cross-reference against `.memory/adr/` — does this contradict an existing decision?

### Sharpen fuzzy language

Propose precise canonical terms for vague or overloaded language.

### Cross-reference with code

When the user states how something works, check whether the code/docs agree. Surface contradictions.

## Rules

- One question per message. Wait for my answer.
- **Research before recommending.** Cite sources.
- **Present 2-3 viable alternatives** with pro/con/source, then recommend one.
- If the codebase can answer it, explore instead of asking.
- **Do not ask questions with obvious answers.**
- Track all decisions in a running table.

## Decision Tracking

| # | Decision | Rationale | Confidence |
|---|----------|-----------|------------|

Present the full table when the interview concludes.

## ADRs

Only offer when ALL THREE are true:
1. **Hard to reverse** — cost of changing later is meaningful
2. **Surprising without context** — future reader will wonder why
3. **Real trade-off** — genuine alternatives existed

Format: `.memory/adr/NNNN-slug.md` — short title + 1-3 sentences (context, decision, why).

## Project Customization

To inject project-specific domain context without forking this skill, use a **steering pointer** (ADR 0002):

1. Create `.kiro/steering/grill-pointer.md` (always-loaded, ~2 lines):
   "Before starting a grill-with-docs session, read `.kiro/steering/grill-context.md`"
2. Create `.kiro/steering/grill-context.md` with `inclusion: manual` containing:
   - Domain constraints, research source priority
   - Domain-specific questions to always ask
   - Cross-reference targets (ADRs, docs, specs)

Cost: ~50 chars always-loaded. Global skill runs unmodified.

## Context Persistence (mandatory)

**At session start:** create `.memory/grill/{topic-slug}/INDEX.md` with the session header and empty questions table.

**After each question is resolved:**
1. Write `.memory/grill/{topic-slug}/Q{nn}-{slug}.md` with question, research, options, decision, and implications
2. Update INDEX.md — add a row linking to the new question file

**This is not optional.** Every resolved question gets its own file. INDEX.md stays current after every entry. See [references/grill-persistence.md](references/grill-persistence.md) for full format.

## Exit Criteria

Complete when:
- All design branches explored
- No unresolved dependencies
- CONTEXT.md updated with new/changed terms
- User confirms shared understanding
- If `recall` is on PATH: persist each decision from the tracking table via `recall add "Q{n}: decided {X} because {Y}" --room decisions --type decision`

Then: summarize decisions, offer ADRs if qualifying, propose first implementation step.
