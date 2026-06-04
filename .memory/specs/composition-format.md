# Composition Format Specification

## Overview

Compositions are YAML manifests that reference and assemble atomic modules into higher-order structures. They are consumed by the generator to produce tool-specific deployments.

## Types

1. **Agent archetypes** — reusable agent role definitions
2. **Crew patterns** — team compositions with routing
3. **Workspace conventions** — file/folder contracts for coordination

## Directory Structure

```
compositions/
├── agent-archetypes/{slug}.yaml
├── crew-patterns/{slug}.yaml
└── workspace-conventions/{slug}.yaml
```

Each composition has an optional companion `README.md` for human context.

---

## Agent Archetype Format

```yaml
name: researcher
description: Deep investigation agent that finds evidence before recommending.
archetype: worker | orchestrator | dispatcher

skills:
  - prior-art
  - five-whys
  - deep-dive

eager-context:
  - verification    # scope: worker applied automatically

tools:
  - read
  - grep
  - glob
  - web_search

prompt: |
  You are a researcher. Investigate thoroughly before concluding.
  Every claim must cite a source. If you cannot find evidence, say so.

escalation: |
  If blocked after 2 search attempts, report what you tried and what's missing.
```

### Agent Archetype Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Agent identity. Lowercase, hyphens. |
| `description` | Yes | What this agent does and when to use it. |
| `archetype` | Yes | Behavioral tier: `worker`, `orchestrator`, `dispatcher` |
| `skills` | No | List of skill slugs this agent can access (lazy-loaded) |
| `eager-context` | No | List of eager-context slugs always loaded for this agent |
| `tools` | Yes | Tool allowlist (least-privilege) |
| `prompt` | Yes | Behavioral instructions (system prompt body) |
| `escalation` | No | What to do when blocked |

---

## Crew Pattern Format

```yaml
name: research
description: Research, investigation, and knowledge capture.

agents:
  lead: research-lead
  workers:
    - researcher
    - internal-researcher
    - external-researcher
    - writer
    - fact-checker
    - editor

routing:
  - pattern: "research|investigate|survey|find out"
    target: research-lead
  - pattern: "write up|document findings"
    target: writer

delegation:
  style: lead-delegates  # lead assigns work to workers
  constraints:
    - Workers cannot delegate to other workers
    - Lead must verify before reporting done

shared-skills:
  - source-citations
  - research-methodology
```

### Crew Pattern Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Crew identity. |
| `description` | Yes | What domain this crew serves. |
| `agents.lead` | Yes | Orchestrator archetype slug. |
| `agents.workers` | Yes | List of worker archetype slugs. |
| `routing` | No | Pattern-based routing rules for the dispatcher. |
| `delegation` | No | How work flows within the crew. |
| `shared-skills` | No | Skills available to all agents in this crew. |

---

## Workspace Convention Format

```yaml
name: standard
description: Two-root workspace with handoff artifact and frontmatter requirements.

roots:
  ephemeral: .scratch
  durable: .memory

artifacts:
  handoff:
    path: "{ephemeral}/HANDOFF.md"
    template: handoff-template  # skill slug for the template
    frontmatter:
      - created_at    # ISO 8601 with offset
      - base_commit   # git rev-parse --short HEAD
      - handoff_key   # workstream slug for supersession
    sections:
      - Objective
      - Constraints
      - Prior Decisions
      - Current State
      - Next Steps
      - Evidence       # optional

frontmatter-rule: |
  Any artifact another agent or future session may read MUST carry:
  created_at and base_commit in YAML frontmatter.

eager-context:
  - workspace        # emits the workspace contract as always-loaded context
```

### Workspace Convention Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Convention identity. |
| `description` | Yes | What this convention provides. |
| `roots` | Yes | Named filesystem roots with paths. |
| `artifacts` | No | Named artifact definitions with templates and structure. |
| `frontmatter-rule` | No | Rules for shared artifact metadata. |
| `eager-context` | No | Eager-context modules that describe this workspace to agents. |

---

## Validation Rules

- All skill/eager-context references resolve to existing modules in `atomics/`
- Agent archetype references in crew patterns resolve to existing archetypes
- No circular references between compositions
- YAML is well-formed and passes schema validation
