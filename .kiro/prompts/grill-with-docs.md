---
name: grill-with-docs
description: "Design interrogation with evidence-backed recommendations. Researches each question via web search before presenting options. Updates CONTEXT.md and offers ADRs inline."
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Ask one question at a time. Wait for my answer before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead.

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

## Domain Awareness

Look for existing documentation:
- `.memory/CONTEXT.md` — domain glossary
- `.memory/adr/` — architectural decision records
- `docs/` — project documentation
- `resources/` — reference repos

## During the Session

### Maintain CONTEXT.md

- If `.memory/CONTEXT.md` doesn't exist, create it on first term resolution
- When a term is resolved or clarified, update CONTEXT.md immediately — don't batch
- Any term with a project-specific meaning distinct from everyday English belongs in the glossary
- Format: `**Term**: Definition. _Avoid_: synonym.`
- CONTEXT.md is a glossary ONLY — no implementation details, no specs, no scratch notes

### What qualifies as a term

- Domain concepts (what the project calls things)
- Internal naming decisions (why we say X not Y)
- Infrastructure conventions (what "deploy" means here)
- Abbreviations and acronyms in the codebase
- Anything where two reasonable people might use different words for the same thing

### Challenge against the glossary

When the user uses a term that conflicts with CONTEXT.md, call it out: "Your glossary defines 'X' as Y, but you seem to mean Z — which is it?"

### Challenge against existing decisions

Cross-reference against `.memory/adr/` — does this contradict an existing decision?

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term.

### Discuss concrete scenarios

Stress-test domain relationships with specific scenarios that probe edge cases and force precision about boundaries.

### Cross-reference with code

When the user states how something works, check whether the code/docs agree. Surface contradictions.

## Rules

- One question per message. Wait for my answer.
- **Research before recommending.** Cite sources.
- **Present 2-3 viable alternatives** with pro/con/source, then recommend one.
- If the codebase can answer it, explore instead of asking.
- **Do not ask questions with obvious answers.** If the answer follows from stated goals or prior decisions — resolve it yourself and move on.
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

## Exit Criteria

Complete when:
- All design branches explored
- No unresolved dependencies
- CONTEXT.md updated with new/changed terms
- User confirms shared understanding

Then: summarize decisions, offer ADRs if qualifying, propose first implementation step.
