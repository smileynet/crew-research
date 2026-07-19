---
name: grill-with-docs
description: "Design interrogation with evidence-backed recommendations. Researches each question via web search before presenting options. Updates CONTEXT.md and offers ADRs inline. Dispatches spikes for empirical validation. Trigger: grill, grill me, stress-test this plan, interrogate this design, poke holes, challenge my assumptions."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Grill With Docs

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one.

Ask one question at a time. Wait for my answer before continuing.

**Self-answer gate (mandatory):** Before asking ANY question, check: can the codebase, docs, or a web search answer this? If yes, explore and state what you found — do not ask. Only ask when the answer requires user intent, preference, or constraints not discoverable from available sources.

## Research Gates (mandatory before presenting options)

Research each genuine design question BEFORE presenting it: docs, prior art, anti-patterns, ecosystem health. Full protocol (classification axes, presentation format, skip conditions): [references/research-protocol.md](references/research-protocol.md).

| # | Gate | Fail action |
|---|------|-------------|
| G1 | Found relevant docs/examples for this technology | Search `"{technology} {concept} docs"` |
| G2 | Searched for WARNINGS against this approach | Search `"{technology} {approach} problems"` or `"deprecated"` |
| G3 | Found 2+ independent sources before recommending | Broaden; if only 1 source, label "unconfirmed" |

Do NOT present options until all 3 gates pass. Present 2-3 viable options as a table (Option | Pro | Con | Source) with a confidence label (High/Medium/Low), then recommend one. G2 findings MUST appear in the Con column with source.

## Spike Dispatch

When a question requires empirical validation (not answerable by docs/research alone):

- **Subagent spike** (answerable in minutes): dispatch a subagent with the question, method, and expected return format. Incorporate results immediately.
- **Subagent research** (3+ competing options, user requests "research this"): dispatch parallel research tracks per option — [references/research-dispatch.md](references/research-dispatch.md).
- **Prototype dispatch** (needs its own session/context budget): [references/prototype-dispatch.md](references/prototype-dispatch.md).

## Domain Awareness

Look for existing documentation before asking:

- `.memory/CONTEXT.md` — domain glossary
- `.memory/adr/` — architectural decision records
- `docs/` — project documentation
- `.references/` — reference repos

## During the Session

- **Maintain CONTEXT.md** — create on first term resolution if missing; update immediately when a term resolves (format: `**Term**: Definition. _Avoid_: synonym.`). Glossary only — no implementation details.
- **Challenge against the glossary** — call out terms that conflict with CONTEXT.md.
- **Challenge against existing decisions** — cross-reference `.memory/adr/`; surface contradictions.
- **Sharpen fuzzy language** — propose precise canonical terms for vague or overloaded language.
- **Cross-reference with code** — when the user states how something works, check whether the code/docs agree.

## Rules

- One question per message. Wait for my answer.
- **Research before recommending.** Cite sources.
- If the codebase can answer it, explore instead of asking.
- **Do not ask questions with obvious answers.**
- Track all decisions in a running table.

## Decision Tracking

| # | Decision | Rationale | Confidence |
|---|----------|-----------|------------|

Present the full table when the interview concludes.

If archwright skills are available and decisions carry recurring force tensions, offer to graduate them into `design/forces/` via `archwright-forces` (traceable provenance beats a table).

## ADRs

Only offer when ALL THREE are true:

1. **Hard to reverse** — cost of changing later is meaningful
2. **Surprising without context** — future reader will wonder why
3. **Real trade-off** — genuine alternatives existed

Format: `.memory/adr/NNNN-slug.md` — short title + 1-3 sentences (context, decision, why).

## Project Customization

Inject project-specific domain context via a **steering pointer** (2-line always-on file directing the agent to a manual-inclusion detail file), never by forking this skill. See ADR 0002.

## Context Persistence (mandatory)

**At session start:** create `.memory/grill/{topic-slug}/INDEX.md` with the session header and empty questions table.

**After each question is resolved:** write `.memory/grill/{topic-slug}/Q{nn}-{slug}.md` (question, research, options, decision, implications) and add a row to INDEX.md. Every resolved question gets its own file — see [references/grill-persistence.md](references/grill-persistence.md) for format.

## Exit Criteria

Complete when: all design branches explored, no unresolved dependencies, CONTEXT.md updated, user confirms shared understanding. If `recall` is on PATH, persist each decision: `recall add "Q{n}: decided {X} because {Y}" --room decisions --type decision`.

Then:

1. Summarize decisions
2. Note **remaining fog** — unresolved questions (need research, spike, or external input). Record in the project's plan or map if one exists.
3. Offer ADRs if qualifying
4. Apply decisions to specs — mark resolved "Unresolved Questions" entries with the decision, remove stale items
5. Propose first implementation step
