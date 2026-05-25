---
title: "Phase 9 Proposal: Additional Crew Patterns"
date: 2026-05-24
status: proposed
---

# Phase 9 Proposal: Additional Crew Patterns

## Objective

Expand from 4 crew patterns to cover the major workflow categories observed in the reference repos. Each new crew should represent a distinct workflow that can't be served by the existing development/bugfix/research/documentation crews.

## Candidate Crews (from reference repo analysis)

| Crew | Workflow | Distinct From |
|------|----------|---------------|
| **infrastructure** | Provisioning, deployment, CI/CD | development (different tools, different risk model) |
| **content** | Presentations, tutorials, workshops | documentation (audience-focused, not code-focused) |
| **review** | Code review, security audit, compliance | development (read-only, judgment-only) |
| **onboarding** | New contributor setup, codebase orientation | research (goal is enablement, not findings) |

## Research Questions (before implementation)

### Q1: Do we need new archetypes, or can existing ones serve?

The reference repo has 70+ specialized agents. We have 7 archetypes. The question is whether new crews need new archetypes or can compose from existing ones.

**Hypothesis**: Most new crews can use existing archetypes with different skill assignments. Only infrastructure likely needs a new archetype (provisioner/deployer with different tool permissions).

**Spike**: For each candidate crew, list the agents it needs and check if our existing archetypes cover them. If >1 new archetype is needed per crew, the crew is worth adding.

### Q2: What's the right granularity for crews?

The reference repo has very specialized crews (crew-builder, crew-maintenance, crew-tooling — all meta-crews for managing the crew system itself). We should avoid this level of specialization.

**Principle**: A crew is worth adding if:
1. It has a distinct workflow (different phase gates, different delegation patterns)
2. It would be selected by a real project in `.crew-config.yaml`
3. It can't be served by an existing crew with different skills

### Q3: How do crews interact?

The reference repo has a dispatcher that routes between crews. We don't have this yet. Questions:
- Does a project use one crew at a time, or multiple simultaneously?
- Who decides which crew handles a request?
- Can work flow between crews (e.g., bugfix crew finds an infra issue → hand off to infrastructure crew)?

**Spike**: Test whether kiro-cli's agent selection (via `--agent`) is sufficient for crew routing, or if we need a dispatcher agent.

### Q4: What skills are missing for new crews?

| Crew | Likely Missing Skills |
|------|---------------------|
| infrastructure | IaC patterns, deployment safety, rollback protocol |
| content | presentation structure, audience analysis, multimedia principles |
| review | (covered by existing code-review + eval-criteria) |
| onboarding | codebase orientation, progressive disclosure for humans |

**Spike**: Check if the reference repo has skills we should port for these crews.

## Spikes to Run

### Spike 1: Archetype Coverage Analysis
For each candidate crew, map required agents to existing archetypes:

```
infrastructure:
  lead → lead ✅
  deploy-planner → planner ✅ (with infra skills)
  provisioner → implementer? (different tools: terraform, docker)
  monitor → tester? (verification, but for infra)
  security-reviewer → reviewer ✅ (with security skills)

content:
  lead → lead ✅
  narrative-writer → writer ✅ (with presentation skills)
  content-researcher → researcher ✅
  tutorial-writer → writer ✅ (with tutorial skills)
  content-reviewer → reviewer ✅
  publisher → writer? (format conversion)

review:
  lead → lead ✅
  reviewer → reviewer ✅
  security-reviewer → reviewer ✅ (with security skills)

onboarding:
  lead → lead ✅
  explorer → researcher ✅
  guide-writer → writer ✅
```

**Decision point**: If an existing archetype can serve with just different skills, don't create a new one. Only create new archetypes for fundamentally different tool/permission profiles.

### Spike 2: Crew Routing Mechanism
Test: can we use kiro-cli's `--agent` flag to select a crew lead, and have the lead delegate within its crew?

```bash
# User selects crew by invoking the lead
kiro-cli chat --agent infrastructure-lead "Deploy the new API to staging"
kiro-cli chat --agent content-lead "Create a presentation about our architecture"
```

If this works, we don't need a dispatcher. If not, we need a top-level dispatcher agent that routes to crew leads.

### Spike 3: Missing Skills Inventory
For each candidate crew, identify skills that don't exist yet and would need authoring:

- infrastructure: `deployment-safety` (rollback protocol, canary patterns), `iac-patterns` (terraform/CDK conventions)
- content: `presentation-structure` (Duarte arc, assertion-evidence), `audience-analysis`
- review: already covered
- onboarding: `codebase-orientation` (how to explain a codebase to a newcomer)

## Proposed Implementation Order

1. **Review crew** (lowest effort — uses existing archetypes + skills, just a new delegation pattern)
2. **Content crew** (medium effort — existing archetypes, needs 1-2 new skills)
3. **Infrastructure crew** (highest effort — may need new archetype for provisioner, needs new skills)
4. **Onboarding crew** (defer — niche use case, can be a variant of research crew)

## Acceptance Criteria

- [ ] Each new crew uses existing archetypes where possible (minimize new archetypes)
- [ ] Each new crew has at least one `.crew-config.yaml` example
- [ ] Generator produces valid deployments for projects selecting new crews
- [ ] New skills authored for crews are <100 lines and pass lint
- [ ] At least one crew (review) is tested end-to-end with a real invocation

## Spike Results

### Spike 1: Archetype Coverage ✅

| Crew | New Archetypes Needed | Notes |
|------|:---------------------:|-------|
| review | 0 | reviewer archetype covers all roles |
| content | 0 | writer + researcher + reviewer cover all roles |
| infrastructure | 1 (operator) | Provisioner/monitor/cleanup need different tool profile |
| onboarding | 0 | researcher + writer cover all roles |

**Decision**: Only infrastructure needs a new archetype. The "operator" runs infra commands (terraform, docker, aws), monitors state, and handles destructive operations — distinct from implementer which writes application code.

### Spike 2: Crew Routing via --agent ✅

**Result**: YES. A lead agent invoked via `--agent lead-name` can delegate to other agents in the same `.kiro/agents/` directory using the `subagent` tool. The worker executed the task and the lead reported back.

**Implication**: No dispatcher needed for manual crew selection. Users invoke the crew lead directly.

### Spike 3: Dispatcher Routing Between Crews ✅

**Result**: YES. A dispatcher agent with only the `subagent` tool correctly routes:
- "Fix the bug" → dev-lead
- "Update the README" → docs-lead

**Implication**: A dispatcher is optional but works. Enables automatic crew selection for projects that want it. Can be added to `.crew-config.yaml` as an opt-in.

### Spike 4: Missing Skills Inventory ✅

| Crew | Missing Skills |
|------|---------------|
| review | 0 — all covered |
| content | 0 — all covered (presentation-writing, tutorial-authoring, diagrams, etc.) |
| infrastructure | 1 — deployment-safety (rollback protocol, canary patterns) |
| onboarding | 0 — all covered |

**Note**: `use_aws` tool is NOT included by default. Infrastructure crew uses standard `shell` tool; projects that need AWS can extend via `.crew-config.yaml`.

## Updated Implementation Plan

Based on spike results, revised effort:

| Crew | New Archetypes | New Skills | Effort |
|------|:-:|:-:|:-:|
| review | 0 | 0 | 15 min |
| content | 0 | 0 | 15 min |
| onboarding | 0 | 0 | 15 min |
| infrastructure | 1 | 1 | 1 session |
| dispatcher (optional) | 1 | 0 | 15 min |

Review, content, and onboarding can be authored immediately — they're just new YAML compositions referencing existing archetypes and skills.
