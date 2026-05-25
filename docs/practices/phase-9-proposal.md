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

## Estimated Effort

| Crew | New Archetypes | New Skills | Sessions |
|------|:-:|:-:|:-:|
| review | 0 | 0 | 0.5 |
| content | 0 | 1-2 | 1 |
| infrastructure | 1 (provisioner) | 2 | 2 |
| onboarding | 0 | 1 | 1 |
| **Total** | **1** | **3-5** | **4-5** |

## Open Questions

1. Should the infrastructure crew have different tool permissions (e.g., `use_aws`)? This would require the archetype format to support tool overrides per-crew.
2. Should crews declare their `scope` (what they handle/refuse) like the reference repo? This would help with routing.
3. Is a dispatcher agent needed, or is manual crew selection (via `--agent`) sufficient for now?
