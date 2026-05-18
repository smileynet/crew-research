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
Tier-first: `atomics/` (skills, eager-context, prompts, eval-definitions), `compositions/` (agent-archetypes, crew-patterns, workspace-conventions), `tools/` (proofs, evals). Skills encompass all on-demand content types (protocols, reasoning-modes, reference, decision, process) distinguished by a `type` field in frontmatter. Eager-context modules are the portable equivalent of kiro-cli steering / CLAUDE.md / AGENTS.md.
_Avoid_: separate directories per skill type, flat layouts, domain-first grouping

**Practice**:
A human-readable research document capturing how to do something well, with rationale and sources. Audience is developers designing the system. May produce zero, one, or many skills as distilled deployment artifacts.
_Avoid_: guide (too vague), tutorial (implies step-by-step learning)

**Skill (refined)**:
An agent-loadable knowledge pack: focused, concise (<100 lines SKILL.md), trigger-rich (description doubles as activation signal). SKILL.md = what to DO; references/ = what to KNOW. Loaded on-demand when description matches current task. Skills are the universal delivery mechanism for all on-demand content types.
_Avoid_: command (procedures are not skills), reference doc (too passive)

**Skill type**:
A frontmatter field (`type:`) that classifies the internal structure of a skill. Types: `protocol` (imperative steps with gates), `reasoning-mode` (thinking pattern activation), `reference` (lookup tables, patterns), `decision` (selection criteria), `process` (numbered workflow steps). Naming convention provides additional signal (e.g., `-protocol` suffix).
_Avoid_: separate filesystem directories per type

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

**Context loading strategy**:
The fundamental mechanism by which content reaches an agent's context window. Three tiers: eager (always-on), lazy (on-demand), progressive (depth-on-demand within a loaded skill).
_Avoid_: conflating delivery timing with content type

**Eager-loaded context**:
Content injected at session start and present every turn regardless of task. The portable concept behind kiro-cli "steering," Claude Code "CLAUDE.md," and Codex/Pi "AGENTS.md." Use for content that applies regardless of task (conventions, constraints, workspace contract).
_Avoid_: steering (tool-specific term), system prompt (too broad)

**Hierarchical eager loading**:
Per-directory eager context loaded bottom-up based on which file is being worked on. Currently Claude Code-specific (nested CLAUDE.md files). Provides localized eager context without bloating the root.
_Avoid_: assuming all tools support this (kiro-cli steering is flat)

**Lazy-loaded context (skills)**:
Content loaded on-demand when the skill's description matches the current task. The agent sees only name + description at startup; full content loads when triggered. All tools support this via SKILL.md directories.
_Avoid_: eager loading situational content (wastes context budget)

**Progressive loading (within skills)**:
Depth-on-demand within an already-loaded skill. SKILL.md is the entry point (<100 lines); companion files (references/, EXAMPLES.md, cookbook/) load only when the agent needs more detail. Keeps token cost proportional to task complexity.
_Avoid_: monolithic skills, loading all companion files upfront
