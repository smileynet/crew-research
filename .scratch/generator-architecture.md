---
created_at: 2026-05-21T21:42:00-07:00
base_commit: 660211e
---

# Agent-Crews Generator Architecture (Reverse Engineering)

## Overview

The agent-crews generator (`generate.py` + `_lib/`) transforms crew YAML definitions into deployable kiro-cli agent JSON. Key insight: it's a multi-pass pipeline with strict ordering dependencies.

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

## Merge Semantics (the most important design pattern)

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

## Crew YAML Schema (from general.yaml)

```yaml
workflow: crew-name
scope:
  handles: ["what this crew does"]
  refuses: ["what triggers handoff elsewhere"]
tools: [base tools for all agents]
allowedTools: [auto-approved for all]
toolsSettings: {canonical_name: {config}}
resources: [base resources for all]
hooks:
  agentSpawn: [{command: "..."}]

archetypes:  # (also accepts "architypes" for backward compat)
  - type: orchestrator | worker
    tools: [archetype-level tools]
    prompt: |
      Archetype-level behavioral prompt
    agents:
      - name: agent-name
        description: "[Category] Role — details"
        routes: "when to dispatch to this agent"
        keyboardShortcut: "ctrl+shift+x"
        welcomeMessage: "..."
        prompt: |
          Agent-specific prompt (appended to archetype)
        resources: [agent-specific resources]
        tools: [REPLACES archetype tools if declared]
```

## Key Lessons for Our Generator

1. **Replacement vs additive must be explicit** — the biggest source of confusion in agent-crews was tools being replacement while resources are additive. Document this clearly.

2. **Dispatcher should be auto-generated** — defining it manually leads to drift. Generate from crew lead descriptions.

3. **Source/output separation** — `.crews/` (source) vs `.kiro/` (generated output) prevents accidental edits to generated files.

4. **Ordering dependencies are the hardest bugs** — prompts must be synced before generation, dispatcher after all crews, components after agents. Our generator must enforce this.

5. **In-place modification is fragile** — `inject_subagents_into_orchestrators()` modifies JSON files after initial generation. Better to compose fully before writing.

6. **Template variables in prompts** — `{{agent_name}}` substitution happens as a final string replace on the JSON. Simple but effective.

7. **Cross-crew awareness requires global knowledge** — sibling maps, dispatcher routing tables, and handoff awareness all need to see ALL crews before generating any single agent's final prompt.

## What We Should Do Differently

- **Compose fully in memory, write once** (no in-place modification)
- **Make merge semantics configurable per-field** (not hardcoded)
- **Validate before writing** (not after)
- **Support multiple output formats** (not just kiro-cli JSON)
- **Abstract the auto-wiring** (routing tables, worker tables as composable templates, not hardcoded markdown)
