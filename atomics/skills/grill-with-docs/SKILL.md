---
name: grill-with-docs
description: "Design interrogation with evidence-backed recommendations. Researches each question via web search before presenting options. Updates CONTEXT.md and offers ADRs inline. Dispatches spikes for empirical validation."
metadata:
  type: process
  invocation: user-only
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

## Spike Dispatch

When a question requires empirical validation (not answerable by docs/research alone):

1. Propose the spike: state the hypothesis, method, and time-box
2. Ask: "This needs a spike. Run now (parallel session) or queue for after?"
3. Write dispatch doc to `.scratch/spikes/{slug}.md`:

```markdown
---
type: spike
status: pending
parent: grill-with-docs
question: "Does X actually work when Y?"
return_to: .scratch/spikes/{slug}-results.md
---

# Spike: {title}

## Question
{The specific question this spike answers}

## Hypothesis
{What we expect to find}

## Method
{Steps to execute — specific, actionable}

## Constraints
- Time-box: {duration}
- Scope: {what's in/out}

## Return Format
Write results to `.scratch/spikes/{slug}-results.md`:
- **Verdict**: confirmed / refuted / inconclusive
- **Evidence**: what you observed
- **Implications**: how this affects the design decision

## Context
{Relevant files, prior decisions, constraints}
```

4. If `.scratch/spikes/{slug}-results.md` exists, read and incorporate into the decision
5. Track in decision table with confidence "Pending spike" until results arrive

## Domain Awareness

Look for existing documentation:
- `.memory/CONTEXT.md` — domain glossary
- `.memory/adr/` — architectural decision records
- `docs/` — project documentation
- `references/` — reference repos

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

## Exit Criteria

Complete when:
- All design branches explored
- No unresolved dependencies
- CONTEXT.md updated with new/changed terms
- User confirms shared understanding

Then: summarize decisions, offer ADRs if qualifying, propose first implementation step.
