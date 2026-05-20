# Crew Research Plan

Monorepo of independent tools for building consistent, reusable behavioral modules (skills, eager-context, agent archetypes, crews) across multiple AI coding tools (kiro-cli, Claude Code, Codex, Pi, etc.).

## Design Decisions Summary

| # | Decision | Choice |
|---|----------|--------|
| 1 | Primary consumer | Standalone modules + optional generator |
| 2 | Canonical format | Markdown + YAML frontmatter, directory-based |
| 3 | Scope boundary | Two tiers: atomics + compositions |
| 4 | Reference mechanism | Name-based, resolved by convention per tool |
| 5 | Monorepo layout | Tier-first: atomics/, compositions/, tools/ |
| 6 | Practice-skill relationship | Practices are source research; skills are distilled deployment |
| 7 | Practice location | docs/practices/ with frontmatter cross-links |
| 8 | Reasoning modes | Individual skills with `type: reasoning-mode` |
| 9 | Protocols | Skills with `type: protocol` |
| 10 | Context loading | Eager / lazy / progressive (tool-agnostic taxonomy) |
| 11 | Prompts | Unified into skills with `invocation: user-only` |
| 12 | Eval definitions | Live in tools/ with their harnesses |
| 13 | Skill evaluation | Dual-run comparison (with/without, measure delta) |
| 14 | Composition format | YAML manifests (structured references) |

## Monorepo Layout

```
atomics/
  skills/                  # all on-demand content types
compositions/
  agent-archetypes/        # YAML: agent role definitions
  crew-patterns/           # YAML: team compositions
  workspace-conventions/   # YAML: file/folder contracts
tools/
  proofs/                  # Phase 1: platform assumption validation
  evals/                   # Phase 2: behavioral evaluation
docs/
  plan.md                  # this file
  inventory.md             # artifact inventory across reference repos
  practices/               # human research docs
  specs/                   # feature specifications
resources/                 # symlinked reference repos (read-only)
.memory/                   # glossary (CONTEXT.md) + ADRs
.scratch/                  # ephemeral handoffs
```

## Phases

### Phase 1: Proof Harness
Validate platform assumptions (context loading, skill activation, agent isolation) across tools using declarative proof definitions + tool adapters.

Spec: [docs/specs/proof-harness.md](specs/proof-harness.md)

### Phase 2: Eval Harness
LLM-as-judge behavioral evaluation with dual-run skill comparison. Proves skills add value against baseline.

Spec: [docs/specs/eval-harness.md](specs/eval-harness.md)

### Phase 3: Module Authoring
Populate atomics/ with skills consolidated from reference repos. Validate each with the eval harness.

### Phase 4: Composition Authoring
Define agent archetypes and crew patterns. Generate deployments for target tools.

### Phase 5: Generator
Optional build layer that composes modules into tool-specific deployments.

Spec: [docs/specs/generator.md](specs/generator.md)

## Specifications

- [Skill Format](specs/skill-format.md) — directory structure, frontmatter, type templates
- [Eager-Context](specs/eager-context.md) — always-loaded context format and delivery
- [Composition Format](specs/composition-format.md) — archetypes, crews, workspace conventions
- [Practice-Skill Cross-Links](specs/practice-skill-crosslinks.md) — linking convention and enforcement
- [Proof Harness](specs/proof-harness.md) — Phase 1 platform validation
- [Eval Harness](specs/eval-harness.md) — Phase 2 behavioral evaluation
- [Tool Adapters](specs/tool-adapters.md) — per-tool CLI profiles
- [Generator](specs/generator.md) — optional build layer

## Key Concepts

- **Skill**: universal delivery mechanism for on-demand agent knowledge (protocols, reasoning modes, reference, prompts)
- **Eager-context**: always-loaded project context (portable steering/CLAUDE.md/AGENTS.md)
- **Composition**: YAML manifest assembling atomics into deployable structures
- **Tool adapter**: maps abstract operations to tool-specific CLI syntax
- **Dual-run evaluation**: with/without skill comparison proving skill value
- **Progressive loading**: depth-on-demand within skills (references/, examples)

## Backlog

GitHub Issues: `gh issue list --repo smileynet/crew-research`

- [#1](https://github.com/smileynet/crew-research/issues/1) — Design per-project module customization
- [#2](https://github.com/smileynet/crew-research/issues/2) — Consider issue management automation
