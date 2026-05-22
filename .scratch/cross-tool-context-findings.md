---
created_at: 2026-05-21T20:24:00-07:00
base_commit: 4f7904f
---

# Cross-Tool Context Delivery Findings

## Discovery

Running proofs against Claude Code revealed a fundamental architectural difference in how tools deliver context to agents:

| Mechanism | kiro-cli | Claude Code |
|-----------|----------|-------------|
| Always-loaded files on agent | `resources: ["file://path"]` in agent JSON | Not supported on custom agents |
| Always-loaded project context | `.kiro/steering/**/*.md` (default agent only) | `CLAUDE.md` (all agents, hierarchical) |
| On-demand knowledge | `resources: ["skill://path"]` in agent JSON | `.claude/skills/*/SKILL.md` (auto-discovered) |
| Agent-scoped tools | `tools: [...]` in agent JSON | `allowedTools: [...]` in agent markdown |

## Key Difference

**kiro-cli** binds context to agents explicitly — each agent declares what files and skills it can access via `resources`.

**Claude Code** uses project-wide discovery — all skills in `.claude/skills/` are available to all agents. Context scoping is done via skill descriptions (activation triggers), not via agent-level resource declarations.

This means our proof definitions can't use the same fixture deployment strategy across tools. A proof that tests "agent X sees file Y" works differently:
- kiro-cli: deploy file, add `file://` to agent's resources
- Claude Code: deploy as CLAUDE.md (eager) or as a skill with matching description (lazy)

## Impact on Proof Harness

The current harness deploys fixtures assuming kiro-cli's model (agent JSON with resources). To support Claude Code, it needs:

1. **Adapter-aware fixture deployment** — the adapter should declare HOW to make content available to an agent (resource field vs skill vs CLAUDE.md)
2. **Proof definitions may need tool-specific fixture variants** — or we need an abstraction layer that maps "make this content available eagerly" to the right mechanism per tool

## Impact on Compositions

Agent archetypes in our composition format declare `skills: [list]` and `eager-context: [list]`. The generator must map these differently:
- kiro-cli: emit as `resources: ["skill://...", "file://..."]` in agent JSON
- Claude Code: place skills in `.claude/skills/`, merge eager-context into CLAUDE.md (agent can't scope it)

**Claude Code has no per-agent skill scoping.** All skills are project-wide. This means a crew with 5 agents where each has different skills... all agents see all skills in Claude Code. The only control is `disable-model-invocation` (hide from auto-loading) and description quality (activation triggers).

## New Questions

1. **Is per-agent skill scoping important enough to solve?** If yes, Claude Code's subagent `skills` preloading field may be the answer (skills injected into subagent context at spawn).
2. **Should proof definitions be tool-agnostic or tool-specific?** A single proof definition that works across tools requires an abstraction layer. Tool-specific proofs are simpler but duplicate effort.
3. **How do we test eager-context isolation in Claude Code?** In kiro-cli, custom agents don't get steering unless declared. In Claude Code, CLAUDE.md loads for ALL agents. There's no equivalent isolation test.
