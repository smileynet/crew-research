# Generator Architecture (Reverse-Engineered from agent-crews)

## Pipeline Order (critical — must execute in this sequence)

1. Sync steering/skills/prompts to project (prompts read at build time for welcomeMessage)
2. Resolve workspace (create .scratch/.memory dirs)
3. Copy base crew YAMLs to temporary `.kiro/crews/`
4. Generate all crew agents (archetype + agent merge → JSON)
5. Build sibling map (cross-crew awareness)
6. Synthesize dispatcher (auto-generated from all crew leads)
7. Generate components (steering files + subagent JSON)
8. Inject shared subagents into orchestrators (modifies JSON in place)
9. Cleanup temporary files

## Merge Semantics

Three-layer merge: workflow → archetype → agent

| Field | Merge Strategy | Who Wins |
|-------|---------------|----------|
| `tools`, `allowedTools`, `toolsSettings` | **Full replacement** | Agent replaces archetype replaces workflow |
| `resources`, `hooks`, `mcpServers` | **Deduplicated concatenation** | All layers contribute, deduped |
| `prompt` | **Concatenation** | Archetype + agent joined with `\n\n` |
| Dict fields | **Deep merge** | Recursive merge, deeper wins |

**Critical gotcha:** An agent that declares `tools:` loses ALL workflow/archetype tools. It's replacement, not additive.

## Auto-Wiring (what the generator injects automatically)

For orchestrators (agents with `subagent` tool):
- `## Your Workers` — markdown table from worker descriptions
- `## Routing Table` — from workers' `routes` fields
- `## Handoff Awareness` — sibling crew leads
- `## Scope Boundary` — from `scope.refuses`
- `availableAgents`/`trustedAgents` in toolsSettings

For dispatcher (always auto-generated, never in crew YAML):
- Routing table from ALL crew leads
- Scope boundary

## Component System

Components are behavioral concerns (verification, git, handoff, etc.) that generate:
- Steering files (targeted to universal/orchestrator/worker)
- Optional subagent JSON files
- Script files
- Allowed commands merged into worker agents

Resolution: fleet defaults → project `behavior` config (deep merge)
Variant system: `sanity_gate: assumption-register` loads specific variant YAML

## Design Principles for Our Generator

1. **Compose fully in memory, write once** (no in-place modification)
2. **Make merge semantics configurable per-field** (not hardcoded)
3. **Validate before writing** (not after)
4. **Support multiple output formats** (not just kiro-cli JSON)
5. **Abstract the auto-wiring** (routing tables, worker tables as composable templates)
