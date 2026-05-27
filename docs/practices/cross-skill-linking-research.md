---
title: "Cross-Skill Linking as Activation Strategy"
date: 2026-05-27
status: proposed
skills: []
---

# Cross-Skill Linking as Activation Strategy

## Problem

E7 revealed 3 skills that fail to activate reliably (diagrams 0%, ai-generation-hygiene 20%, verification-protocol 40%). These skills share a trait: they apply **during** other work rather than being the primary task. Users don't say "apply hygiene rules" — they say "write a function" and expect hygiene to be applied implicitly.

## Hypothesis

If a reliably-activating skill references a failing skill in its workflow steps, the agent may load the referenced skill via progressive loading (following markdown links to companion files). This turns failing skills into **workflow participants** invoked by context rather than by direct description match.

## Prior Art Research

### Pattern 1: Companion Files (matt-skills, nicobailon)

Both repos use markdown links within SKILL.md to reference companion files:
- `[tests.md](tests.md)` — matt-skills TDD skill links to testing guidelines
- `[REFERENCE.md](REFERENCE.md)` — progressive disclosure of detail
- `references/component-gallery/` — nicobailon design-deck loads on demand

**Key insight**: These are intra-skill links (within the same skill directory). The agent reads the SKILL.md, sees the link, and follows it when relevant. This is progressive loading within a single skill, not cross-skill activation.

### Pattern 2: Prompt-Driven Skill Loading (nicobailon)

Nicobailon's prompts explicitly instruct: "Load the `design-deck` skill for the full format reference." This is a **hard directive** in a user-invoked prompt that forces skill loading regardless of description matching.

**Key insight**: This bypasses activation entirely — the prompt tells the agent what to load. Works for user-invoked workflows but doesn't help with agent-initiated activation.

### Pattern 3: Eager Loading for Broad-Applicability (agent-crews)

Agent-crews puts `ai-generation-hygiene` as **steering** (`inclusion: always`), not as a skill. Broad-applicability content that should apply during all code generation is eager-loaded.

**Key insight**: The prior art's answer to "this should always apply" is: don't make it a skill. Make it steering. This is the simplest solution but costs context budget every turn.

### Pattern 4: Archetype-Scoped Skill Binding (agent-crews)

Agent-crews binds skills to archetypes at build time:
- Workers get: verification-protocol, git-protocol, troubleshooting-protocol
- Orchestrators get: completion-protocol

The generator injects `skill://` references into agent JSON based on archetype. Skills are pre-bound, not discovered.

**Key insight**: This is "forced activation by role" — the skill is always available to the agent because it's in its resources, not because the description matched. The agent still decides whether to load it, but it's guaranteed to be in the candidate set.

### Pattern 5: Soft Dependencies (matt-skills ADR-0001)

Matt-skills distinguishes:
- **Hard dependency**: skill explicitly says "run `/setup-matt-pocock-skills` if not configured"
- **Soft dependency**: skill vaguely references "the project's domain glossary" — works without it, just less sharp

**Key insight**: Cross-skill references can be soft (mention the concept, let the agent decide) or hard (explicitly instruct loading). Soft references don't guarantee activation but don't break if the referenced skill is absent.

## Proposed Linking Mechanisms (Ranked by Feasibility)

### Mechanism A: Inline Workflow References

Add a step in a reliably-activating skill that mentions the failing skill's domain:

```markdown
## After Implementation
- Apply [code hygiene checks](../ai-generation-hygiene/SKILL.md) before committing
```

**Hypothesis**: If kiro-cli follows relative markdown links from a loaded skill to another skill's SKILL.md, this triggers progressive loading of the referenced skill.

**Risk**: kiro-cli may not follow cross-directory links. Progressive loading may only work within a single skill directory.

### Mechanism B: Companion File in Host Skill

Create a companion file inside the host skill that contains the failing skill's content:

```
atomics/skills/script-authoring/
├── SKILL.md
└── references/code-hygiene.md  ← content from ai-generation-hygiene
```

**Hypothesis**: The agent follows intra-skill links reliably (confirmed by matt-skills pattern). Embedding the content as a companion file guarantees it's reachable.

**Risk**: Content duplication. Drift between the companion and the source skill.

### Mechanism C: Description Enhancement with Workflow Context

Rewrite failing skill descriptions to include the workflow context:

```yaml
# Before:
description: "Eliminate common AI-generation artifacts from produced code."

# After:
description: "Code hygiene rules applied during any code generation, implementation, or scripting task. Catches redundant checks, gratuitous logging, restating comments. Always relevant when writing code."
```

**Hypothesis**: Adding "any code generation, implementation, or scripting task" to the description gives kiro-cli's matcher more surface area to trigger on.

**Risk**: May still not match because the user's query is "write a function" not "apply code hygiene."

### Mechanism D: Eager-Load the Failing Skills

Move the 3 failing skills to `.kiro/steering/` (always-loaded):

**Hypothesis**: Guaranteed activation. No matching needed.

**Risk**: Adds ~200 lines to every turn's context. Only 3 skills, so ~600 tokens — acceptable given the skill focusing effect (skills reduce total tokens).

## Experiment Design

### Experiment E15: Cross-Skill Link Activation

**Question**: Does referencing a failing skill from a reliably-activating skill cause the failing skill to load?

**Method**:
1. Modify `script-authoring` SKILL.md to add: "Before finalizing, review output against [code hygiene rules](../ai-generation-hygiene/SKILL.md)"
2. Run the same 5 tasks that failed for ai-generation-hygiene
3. Check if ai-generation-hygiene activates when script-authoring is the primary skill

**Conditions**:
- Baseline: current state (no cross-link)
- Treatment A: relative markdown link to other skill's SKILL.md
- Treatment B: inline summary of hygiene rules (no link, just text)
- Treatment C: companion file within script-authoring/references/

**Metrics**: activation rate for ai-generation-hygiene, token usage delta

**Acceptance**: If any treatment achieves >60% activation for the failing skill, cross-linking is viable.

### Experiment E16: Description Rewriting vs Eager Loading

**Question**: Is description rewriting sufficient, or must we eager-load?

**Method**:
1. Rewrite descriptions for diagrams, ai-generation-hygiene, verification-protocol with more workflow-context triggers
2. Re-run E7 activation sweep for just those 3 skills
3. Compare: rewritten description vs eager-loaded (steering)

**Conditions**:
- Baseline: current descriptions (E7 results)
- Treatment A: rewritten descriptions (more trigger words)
- Treatment B: moved to steering (always-loaded)

**Metrics**: activation rate, false positive rate, token usage

**Acceptance**: If rewriting achieves >80% activation without increasing FPR, prefer it over eager-loading.

## Recommendation

Run E15 first (cheapest, most informative). If cross-skill links work in kiro-cli, it's the best solution — no context budget cost, no duplication, natural workflow integration. If they don't work, fall back to E16 (description rewriting, then eager-loading as last resort).

The prior art consensus is clear: **broad-applicability content should be eager-loaded** (agent-crews does this). But our skill focusing effect research suggests the context cost is minimal. The question is whether we can avoid it entirely via linking.
