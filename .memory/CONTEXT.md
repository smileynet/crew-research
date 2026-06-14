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
Tier-first: `atomics/` (skills, eager-context, eval-definitions), `compositions/` (agent-archetypes, crew-patterns, workspace-conventions), `tools/` (proofs, evals). Skills encompass all on-demand content types (protocols, reasoning-modes, reference, decision, process, user-invoked actions) distinguished by `type` and `invocation` fields in frontmatter. The generator maps `invocation: user-only` skills to kiro-cli's `.kiro/prompts/` directory.
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
`docs/development/{slug}.md` — human-readable research docs live in project documentation, not in the deployable module tree.
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

**Prompt (atomic module)**:
Deprecated as a separate deployment target. All user-invocable workflows deploy as skills with `invocation: user-only` metadata. kiro-cli treats skills and prompts identically in the picker (both invocable via `/name` and `@name`), but only skills display their description. The `~/.kiro/prompts/` directory is no longer used by crew-research deployments.
_Avoid_: deploying to prompts/ directory, maintaining separate prompt files

**Invocation control (frontmatter)**:
A field inside `metadata` (`metadata.invocation`) that determines who can trigger a skill. Values: `user-only` (user invokes explicitly, agent cannot auto-load), `agent-only` (agent loads when relevant, hidden from user menu), `both` (default — dual-mode). The generator reads this and emits tool-native fields during deployment. Only standard-compliant fields (`name`, `description`, `metadata`) appear at top level in source.
_Avoid_: putting custom fields at top level (risk of collision with future tool fields), assuming all tools handle invocation the same way

**Skill-backed prompt**:
Deprecated term. In the unified model, a "prompt" is just a skill with `invocation: user-only` that may reference other skills via progressive loading. No separate concept needed.
_Avoid_: duplicating skill content inside prompts, tight coupling between prompt and skill internals

**Skill evaluation (dual-run comparison)**:
The method for proving a skill adds value: run the same task WITH and WITHOUT the skill loaded, score both against criteria derived from the skill's instructions, and measure the delta. The delta is the skill's contribution. Without a baseline comparison, a score is meaningless.
_Avoid_: testing only with skill loaded, leaking skill content into task descriptions, testing generic competence instead of skill-specific behavior

**Activation test**:
A secondary evaluation that checks whether an agent activates a skill when it's available but not forced. Tests description quality and trigger coverage. Expected activation rate without forcing is ~40-50%; with forced evaluation hooks ~84%.
_Avoid_: conflating activation failure with skill quality (may be a description problem, not a content problem)

**Skill focusing effect**:
The empirically observed phenomenon where loading skills REDUCES token usage (counter to the "skills add overhead" hypothesis). Skills provide structure that helps the agent follow a more direct path. Measured: 6 skills = 33% fewer tokens than no skills. Only applies when skills are concise (<100 lines).
_Avoid_: assuming skills always add context pressure

**Activation bottleneck**:
The primary limitation of on-demand skill loading: skills work when loaded but kiro-cli's semantic matching frequently fails to trigger them. Distinctive trigger words in descriptions survive; generic phrases don't. Skills that can't reliably activate should be eager-loaded instead.
_Avoid_: blaming skill content for activation failures (it's a description/matching problem)

**Composition format**:
YAML manifests in `compositions/`. Compositions are structured references to atomic modules (agent lists, skill references, routing tables), not prose instructions. Machine-readable for generators; companion README for human context.
_Avoid_: using SKILL.md format for compositions, mixing prose instructions with structured declarations

**Agent archetype (composition)**:
A YAML manifest declaring an agent's name, description, tools, skill references, eager-context references, and behavioral prompt. The generator emits tool-specific agent configs from this.
_Avoid_: hardcoding tool-specific fields (JSON agent format is a delivery detail)

**Crew pattern (composition)**:
A YAML manifest declaring which agent archetypes compose the crew, routing rules, delegation structure, and shared context. The generator emits tool-specific multi-agent deployments from this.
_Avoid_: embedding agent definitions inline (reference by name instead)

**Workspace convention (composition)**:
A YAML manifest declaring file/folder structures, artifact templates, lifecycle rules, and eager-context modules that a project adopts. Defines the shared contract agents rely on for coordination.
_Avoid_: mixing workspace structure with agent behavior (workspace is infrastructure, not behavior)

**Spike**:
Time-boxed throwaway investigation answering "is this feasible?" Output: findings + pass/fail verdict. Code discarded, learnings kept. One hypothesis per spike, time-box to 1 day.
_Avoid_: prototype (answers different question), tracer bullet (code is kept)

**Tracer bullet**:
Thin end-to-end slice through all layers, kept as production code. Answers "does the path work?" Minimal but real — hardcoded values, single case, no edge cases. Becomes the skeleton for the full feature.
_Avoid_: prototype (thrown away), spike (feasibility only)

**Prototype**:
Throwaway code answering a design question — "does this feel right?" Routes between logic (TUI state explorer) and UI (multi-variant page). Code discarded, answer captured in commit/ADR/notes.
_Avoid_: spike (feasibility), tracer bullet (production code)

**Validation checkpoint**:
Mid-implementation comparison of plan vs reality. Produces a table (Plan Item | Implemented? | Issue), fixes misalignments, documents findings that impact future work, updates the plan. Used in poc-workflow and any multi-phase implementation.
_Avoid_: post-mortem (that's after the fact), review (too vague)

**Cross-skill linking**:
Referencing one skill from another's workflow steps to trigger progressive loading of the referenced skill. Proposed mechanism for activating broad-applicability skills (ai-generation-hygiene, verification-protocol, diagrams) that fail direct description-based activation. Unvalidated — pending E15 experiment.
_Avoid_: eager loading (always-on, different mechanism), skill composition (too vague)

**Documentation**:
User-facing content intended for humans to read (README.md, docs/, wikis, tutorials, changelogs).
_Avoid_: using "docs" to mean agent guidance files

**Guidance**:
Agent-facing content that shapes AI behavior (AGENTS.md, steering, skills, .memory/, .scratch/).
_Avoid_: using "documentation" for agent-loadable files

**Tools directory** (`tools/`):
Project scripts and CLI utilities that automate mechanical tasks — validation, extraction, formatting, deployment, data processing. Agents invoke these rather than reimplementing logic. Should follow the validation contract (JSON output, exit codes). Consider creating a tool when you find yourself repeatedly executing complex commands or writing one-off scripts.
_Avoid_: "utilities", "scripts" (use `tools/` as the standard directory name across projects)


**Session review**:
Periodic analysis of kiro-cli session transcripts to assess agent performance, identify steering/skill gaps, and surface tool candidates. Uses quantitative parsing + subagent fanout for comprehensive coverage.
_Avoid_: post-mortem (that's for incidents), retrospective (that's for teams)

**Research budget**:
Cap on web searches per research question (8-10). Prevents diminishing-returns search sprawl. Stop after 3 consecutive empty results.
_Avoid_: search limit (too generic)

**Promotion** (artifact lifecycle):
Moving an artifact from ephemeral (`.scratch/`) to durable (`.memory/`) when it has lasting value. Triggered during handoff. Opposite of "scratch stays scratch."
_Avoid_: archiving (implies cold storage)


**Project-level skill**:
A specialist skill installed to a specific project's `.kiro/skills/` rather than globally. Suggested by the agent during init, adopt-project, or read-handoff when it detects matching work. Examples: fiction-craft, poc-workflow, skill-authoring. Avoids polluting global space with skills most projects don't need.
_Avoid_: "full tier skill" (full is a global tier), "optional skill" (all skills are optional)

**Three-tier deployment**:
The deployment model: basic (minimal global fundamentals), full (complete lifecycle globally), project-level (specialist skills per-project on demand). Global tiers deploy to `~/.kiro/`, project-level deploys to `<project>/.kiro/skills/`.
_Avoid_: "packs" (no pack mechanism exists), "optional tier" (it's not a tier, it's per-project)
