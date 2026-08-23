---
type: glossary
title: "Context"
---

# Context

**Module**:
A self-contained, reusable behavioral artifact (skill, protocol, agent archetype, etc.) that works standalone and can optionally be composed into tool-specific deployments.
_Avoid_: component (overloaded in agent-crews), plugin, package

**Generator**:
An optional build layer that composes modules into tool-specific deployments (kiro-cli steering, CLAUDE.md, etc.). Not required to use modules.
_Avoid_: compiler, transpiler

**Canonical format**:
Markdown with YAML frontmatter. Simple modules are a single file. Complex modules use a directory with a primary SKILL.md and supporting files.
_Avoid_: pure YAML, JSON config

**Skill directory**:
A folder-based module containing a primary SKILL.md plus optional supporting documents (references/, examples). Supporting files are progressively loaded on demand.
_Avoid_: flat file, monolithic skill

**Atomic module**:
A standalone building block authored, used, and tested independently. Reasoning modes, protocols, skills, steering, and evaluation definitions are atomics.
_Avoid_: primitive (too low-level connotation), leaf

**Composition**:
A higher-order structure that references and assembles atomic modules. Agent archetypes, crew patterns, and workspace conventions are compositions.
_Avoid_: aggregate, bundle, meta-module

**Skill (refined)**:
An agent-loadable knowledge pack: focused, concise (<100 lines SKILL.md), trigger-rich (description doubles as activation signal). SKILL.md = what to DO; references/ = what to KNOW. Loaded on-demand when description matches current task.
_Avoid_: command (procedures are not skills), reference doc (too passive)

**Skill type**:
A frontmatter field (`metadata.type`) classifying a skill's internal structure: `protocol`, `reasoning-mode`, `reference`, `decision`, `process`.
_Avoid_: separate filesystem directories per type

**Practice**:
A human-readable research document in `docs/development/` capturing how to do something well, with rationale and sources. May produce zero, one, or many skills as distilled deployment artifacts.
_Avoid_: guide (too vague), tutorial (implies step-by-step learning)

**Reasoning mode**:
A named keyword activating a specific thinking pattern (e.g., five-whys, pre-mortem, steel-man). Each mode is its own atomic skill with a distinct trigger, independently composable.
_Avoid_: bundling modes into a single collective skill, always-loading as steering

**Spike**:
Time-boxed throwaway investigation answering "is this feasible?" Output: findings + pass/fail verdict. Code discarded, learnings kept.
_Avoid_: prototype (answers different question), tracer bullet (code is kept)

**Tracer bullet**:
Thin end-to-end slice through all layers, kept as production code. Answers "does the path work?" Minimal but real — becomes the skeleton for the full feature.
_Avoid_: prototype (thrown away), spike (feasibility only)

**Prototype**:
Throwaway code answering a design question — "does this feel right?" Code discarded, answer captured in commit/ADR/notes.
_Avoid_: spike (feasibility), tracer bullet (production code)

**Validation checkpoint**:
Mid-implementation comparison of plan vs reality. Produces a table (Plan Item | Implemented? | Issue), fixes misalignments, updates the plan.
_Avoid_: post-mortem (that's after the fact), review (too vague)

**Documentation**:
User-facing content intended for humans to read (README.md, docs/, wikis, tutorials, changelogs).
_Avoid_: using "docs" to mean agent guidance files

**Guidance**:
Agent-facing content that shapes AI behavior (AGENTS.md, steering, skills, .memory/, .scratch/).
_Avoid_: using "documentation" for agent-loadable files

**Tier**:
A named selection of steering + skills (plus extensions) deployed globally as a set. Two tiers: basic (everyday fundamentals) and full (complete lifecycle). Declared in `compositions/tiers/{name}.yaml`.
_Avoid_: plugin, level, pack

**Extension**:
An optional steering + skills bundle declared in a tier manifest, gated on an external prerequisite (a CLI tool on PATH). Auto-deploys during tier deploy when the prerequisite check passes; skippable with `--skip-extension`.
_Avoid_: plugin (superseded), addon (informal)

**Known tool**:
A separately-owned repo (registered in `compositions/known-tools.yaml`) that self-deploys via the symlink convention; crew-research detects it (doctor), lists it (catalog), and routes to it. Example: archwright.
_Avoid_: extension (crew-owned content), plugin (superseded), integration (too vague)

**Project-level skill**:
A specialist skill installed to a specific project's `.kiro/skills/` rather than globally. Suggested during init or read-handoff when matching work is detected.
_Avoid_: "full tier skill" (full is a global tier), "optional skill" (all skills are optional)

**Three-tier deployment**:
The deployment model: basic (minimal global), full (complete lifecycle global), project-level (specialist skills per-project on demand). Global → `~/.kiro/`, project-level → `<project>/.kiro/skills/`.
_Avoid_: "packs" (no pack mechanism), "optional tier" (it's per-project, not a tier)

**Steering pointer**:
A tiny always-loaded steering file (~50 chars) instructing the agent to read a detail file in the skills tree. Provides project-specific knowledge injection without forking global skills.
_Avoid_: extends (full shadow), params (value substitution), placing detail files under steering/

**Steering shadow**:
When always-on steering covers a skill's trigger space, the matcher correctly never loads the redundant skill — activation evals score 0 TPR while behavior stays correct. Measure steering field compliance instead.
_Avoid_: activation failure (behavior isn't failing), matcher bug (the matcher is right)

**Consolidation (skill)**:
Merging a skill that doesn't earn standalone status into a related skill's `references/` companion files. Content survives via progressive loading; the standalone entry point is retired.
_Avoid_: deletion (content is kept), composition (that's assembling atomics)

**Promotion** (artifact lifecycle):
Moving an artifact from ephemeral (`.scratch/`) to durable (`.memory/`) when it has lasting value. Triggered during handoff.
_Avoid_: archiving (implies cold storage)

**Recall**:
Purpose-built Rust CLI (`~/code/recall`) providing cross-session semantic memory. Hybrid BM25 + vector search over ingested conversation history, with agent write-back. Single binary, no runtime deps beyond cached ONNX model.
_Avoid_: MemPalace (upstream project we chose not to wrap), memory system (too generic)

**Wing**:
A project-scoped namespace within the recall database. Auto-derived from session `cwd` metadata during ingest. Enables scoped search without separate databases.
_Avoid_: project (overloaded), namespace (too generic)

**Room**:
A category within a wing that groups related recall memories (defaults to "general"). The middle level of recall's wing/room/drawer hierarchy.
_Avoid_: folder, tag (rooms are structural, not freeform)

**Drawer**:
A single stored memory record in recall — one chunk of content with its embedding, wing, room, and type. The unit of storage and retrieval.
_Avoid_: document (too big), row (implementation term)

**Prime**:
The `recall prime` output — usage instructions + recent agent-written facts + top retrieval results, injected at session start.
_Avoid_: wake-up (MemPalace's term), context dump (too vague)

**Ticket**:
A single unit of work sized to one context window, stored as `.tickets/{NN}-{slug}.md` with YAML frontmatter (status, blocked_by, spec). Describes WHAT to build, not HOW.
_Avoid_: issue (overloaded with GitHub), task (too generic), story (Agile-specific)

**Frontier**:
The set of tickets where `status: open` and all `blocked_by` are `done`. The agent works the frontier — picks the lowest-numbered available ticket.
_Avoid_: backlog (unordered), next (implies single item)

**Birth window**:
The period between a ticket's creation and its id being cited elsewhere. `tkt renumber` is safe only inside it — cited ids are external contracts.
_Avoid_: grace period (implies time-based), provisional id (the id is real, just uncited)

**tkt**:
The git-native ticket CLI implementing the `.tickets/` frontmatter contract — frontier computation, claim allocation, surgical rewrites, contract+decay validation.
_Avoid_: tk (unrelated third-party binary), "the ticket tool" (ambiguous)

**Environment designation (CREW_ENV)**:
Machine-local flag in gitignored `.mise.local.toml` marking a machine as `corp` (agy forbidden) or `personal` (full tool access). Tooling consults it for policy blocks and deploy sets.
_Avoid_: access flag (policy ≠ access), machine profile
