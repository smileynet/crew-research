# Context

**Module**:
A self-contained, reusable behavioral artifact (skill, protocol, agent archetype, etc.) that works standalone and can optionally be composed by a generator into tool-specific deployments.
_Avoid_: component (overloaded in agent-crews), plugin, package

**Generator**:
An optional build layer that composes modules into tool-specific deployments (kiro-cli JSON, CLAUDE.md, Pi config, etc.). Not required to use modules.
_Avoid_: compiler, transpiler

**Canonical format**:
Markdown with YAML frontmatter. Simple modules are a single file. Complex modules use a directory with a primary SKILL.md and supporting files (examples, troubleshooting, etc.).
_Avoid_: pure YAML, JSON config

**Skill directory**:
A folder-based module convention containing a primary SKILL.md plus optional supporting documents (examples, troubleshooting, reference). Supporting files are progressively loaded on demand, not bundled into initial context.
_Avoid_: flat file, monolithic skill

**Progressive loading**:
The pattern where only SKILL.md is loaded initially; additional context files within the skill directory are linked lazily and loaded only when relevant to the current task.
_Avoid_: eager loading, all-at-once injection

**Atomic module**:
A standalone building block that can be authored, used, and tested independently. Reasoning modes, protocols, skills, steering, prompts, and evaluation definitions are atomics.
_Avoid_: primitive (too low-level connotation), leaf

**Composition**:
A higher-order structure that references and assembles atomic modules. Agent archetypes, crew patterns, and workspace conventions are compositions.
_Avoid_: aggregate, bundle, meta-module

**Reference mechanism**:
Compositions reference atomics by name (directory name = identity). The generator resolves names to tool-specific delivery (kiro-cli: `skill://` URI in resources field; Claude Code: symlink to `~/.claude/skills/`; Pi: placement in `~/.pi/agent/skills/`; Codex: placement in `~/.codex/skills/`).
_Avoid_: hardcoded paths, tool-specific URIs in source definitions

**Skill discovery (cross-tool common pattern)**:
All tools scan known filesystem paths for SKILL.md files, extract name + description from frontmatter at startup, and load full content on-demand when the description matches the current task. The skill directory IS the portable unit.
_Avoid_: assuming URI schemes are universal (only kiro-cli uses `skill://`)

**Tool-specific delivery**:
The only difference between tools is WHERE skills are placed and HOW they're registered. The skill content, format, and structure are identical across all tools.
_Avoid_: tool-specific content, per-tool skill variants

**Monorepo layout**:
Tier-first: `atomics/` (skills, protocols, steering, reasoning-modes, prompts, eval-definitions), `compositions/` (agent-archetypes, crew-patterns, workspace-conventions), `tools/` (proofs, evals). Reflects the two-tier model directly in filesystem structure.
_Avoid_: flat layouts, domain-first grouping

**Practice**:
A human-readable research document capturing how to do something well, with rationale and sources. Audience is developers designing the system. May produce zero, one, or many skills as distilled deployment artifacts.
_Avoid_: guide (too vague), tutorial (implies step-by-step learning)

**Skill (refined)**:
An agent-loadable knowledge pack: focused, concise (<100 lines SKILL.md), trigger-rich (description doubles as activation signal). SKILL.md = what to DO; references/ = what to KNOW. Loaded on-demand when description matches current task.
_Avoid_: command (procedures are not skills), reference doc (too passive)

**Practice-to-skill relationship**:
Practices are the source research layer; skills are the distilled deployment artifacts. Same slug tracks lineage. Not every practice produces a skill; not every skill needs a backing practice.
_Avoid_: conflating the two, forcing all practices into skill format

**Practice location**:
`docs/practices/{slug}.md` — human-readable research docs live in project documentation, not in the deployable module tree.
_Avoid_: co-locating practices inside skill directories, mixing human and agent audiences

**Skill location**:
`atomics/skills/{slug}/SKILL.md` — agent-loadable modules live in the tier-first module tree.
_Avoid_: putting skills in docs/, mixing research with deployment artifacts

**Cross-link convention**:
Practices link to derived skills via frontmatter (`skills: [slug]`). Skills link back to source practice via frontmatter (`practice: slug`). Same slug = same concept. Links are optional (not all practices produce skills; not all skills need a backing practice).
_Avoid_: relying solely on naming convention without explicit frontmatter links

**Reasoning mode**:
A named keyword that activates a specific thinking pattern (e.g., five-whys, pre-mortem, steel-man). Each mode is its own atomic skill with a distinct trigger, independently composable and testable.
_Avoid_: bundling modes into a single collective skill, always-loading as steering
