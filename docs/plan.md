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

### Phase 1: Proof Harness ✅ COMPLETE
Validate platform assumptions across tools using declarative proof definitions + tool adapters.

### Phase 2: Eval Harness ✅ COMPLETE
LLM-as-judge behavioral evaluation with dual-run skill comparison. Proves skills add value against baseline.

### Phase 3: Module Authoring ✅ COMPLETE (initial batch)
5 skills authored and evaluated. 6 additional skills ported from reference repos. 3 eager-context modules.

### Phase 4: Composition Authoring ✅ COMPLETE (initial batch)
7 agent archetypes, 4 crew patterns, 1 workspace convention. Generator produces deployments.

### Phase 5: Generator ✅ COMPLETE
Validates references, emits kiro-cli + claude-code deployments from compositions.

---

## Remaining Roadmap

### Phase 6: Complete Skill Library
Port all remaining skills from reference repos (~20 candidates). Assign to archetypes.

### Phase 7: Deferred Experiments (#3)
Run experiments 2-6 across the complete skill set:
- Token efficiency (is quality worth the token cost?)
- Process tracing (does the skill change HOW the agent works?)
- Skill interference (do multiple skills degrade each other?)
- Task diversity (consistent help across task shapes?)
- Skill compression (can we make skills shorter?)

### Phase 8: Per-Project Customization
Design and test how projects override/extend base compositions:
- Rust project adds rust-specific skills to implementer
- Web project adds frontend-specific patterns
- Spike the overlay mechanism, implement in generator

### Phase 9: Additional Crew Patterns
Integrate more crew patterns based on findings from Phase 7-8:
- Infrastructure crew
- Onboarding crew
- Content/publishing crew
- Patterns informed by experiment results

### Phase 10: End-to-End Validation
Create sample projects that baseline and validate the full pipeline:
- Deploy generated output to real projects
- Use crews for real work (bugfix, feature, docs)
- Measure: does the system improve outcomes vs. bare agent?
- Produce benchmark results comparing with/without compositions

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

## Cross-Tool Architecture

| Feature | kiro-cli | Claude Code |
|---------|----------|-------------|
| Agent format | JSON | Markdown + YAML frontmatter |
| Eager context (universal) | `.kiro/steering/` via resources | `CLAUDE.md` (all agents) |
| Eager context (scoped) | Per-agent steering via resources | Subagent system prompt body |
| Skill delivery | `skill://` URI in agent resources | `.claude/skills/` (project-wide) |
| Skill scoping | Per-agent (declared in resources) | Subagent `skills` field (preloaded) |
| User-only skills | `.kiro/prompts/` | `disable-model-invocation: true` |
| Non-interactive | `--no-interactive -a` | `--print` |

## Spikes Resolved

| Spike | Decision |
|-------|----------|
| S1 | Skills = slash commands (TUI). Generator maps `invocation: user-only` → `.kiro/prompts/` |
| S2 | Claude Code strips unknown frontmatter. `metadata` block preserved. |
| S3 | Agent Skills standard extensible. Strip escape hatch if needed. |
| S4 | Judge variance = 0. Config: 1 judge trial, 3 agent trials. |
| S5 | Hybrid Params + Extends for customization. ADR 0002. |
| S6 | Abstract fixture types in proofs. Adapter maps to tool mechanism. |
| S7 | Subagent `skills` field solves per-agent scoping. Scoped eager-context → system prompt. |

## Backlog

GitHub Issues: `gh issue list --repo smileynet/crew-research`

- [#1](https://github.com/smileynet/crew-research/issues/1) — Design per-project module customization
- [#2](https://github.com/smileynet/crew-research/issues/2) — Consider issue management automation
