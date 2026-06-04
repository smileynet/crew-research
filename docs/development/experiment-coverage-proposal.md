---
title: Experiment Coverage Proposal
date: 2026-05-25
status: proposed
---

# Experiment Coverage Proposal

Gaps in test coverage for project items, with proposed experiments to close them.

## Coverage Matrix

| Area | Tested | Gap |
|------|:------:|-----|
| Skill activation (original 5) | ✅ | Need activation tests for 17 new skills |
| Skill quality (dual-run) | ✅ | Only 5 skills evaluated; 24 untested |
| Token efficiency | ✅ | — |
| Skill interference | ✅ | — |
| Process tracing | ✅ | Only 2 skills; need coverage for new protocols |
| Dispatcher routing | ✅ | — |
| Lead→worker delegation | ✅ | — |
| Param substitution | ✅ (functional) | No behavioral test (does the agent USE the substituted values?) |
| New archetypes (operator, dispatcher) | ❌ | Never invoked in a real task |
| New crews (review, content, infra, onboarding) | ❌ | Never tested end-to-end |
| Init workflow | ❌ | Never run on a real project |
| Multi-agent workflow | ❌ | Lead→delegate→verify never tested as full loop |
| Cross-crew handoff | ❌ | Never tested |
| Eager-context effectiveness | ❌ | Does always-loaded context change behavior? |
| Research-output format | ❌ | Does subagent produce structured output? |
| Handoff round-trip | ❌ | Write→read continuity never tested |

## Proposed Experiments

### E7: New Skill Activation Sweep
**Goal**: Verify all 29 skills activate on relevant tasks.
**Method**: Write 2 relevant tasks per new skill, run activation test.
**Effort**: 1 session | **Priority**: P1

### E8: Multi-Agent Workflow
**Goal**: Test the full lead→delegate→verify loop.
**Method**: Invoke lead with a task requiring 2+ workers. Verify: lead delegates, workers complete, lead verifies and reports.
**Fixture**: defu project
**Tasks**: "Plan and implement a new function with tests" (needs planner + implementer + tester)
**Effort**: 1 session | **Priority**: P1

### E9: Crew End-to-End
**Goal**: Test each new crew pattern with a realistic task.
**Method**: For each crew (review, content, infrastructure, onboarding), invoke the lead with a representative task and verify the workflow completes.
**Tasks**:
- review: "Review src/defu.ts for security and quality issues"
- content: "Create a 5-minute presentation explaining how defu works"
- infrastructure: "Write a Dockerfile and CI workflow for this project"
- onboarding: "Create a getting-started guide for new contributors"
**Effort**: 1 session | **Priority**: P1

### E10: Eager-Context Effectiveness
**Goal**: Does always-loaded context (workspace, verification, delegation) change agent behavior?
**Method**: Dual-run comparison — same task with/without eager-context deployed to `.kiro/steering/`.
**Metrics**: Process heuristics (verify-after-change, read-before-write), token usage.
**Effort**: 1 session | **Priority**: P2

### E11: Research-Output Subagent Format
**Goal**: When a researcher subagent is delegated a research task, does it produce the structured output format and write to file?
**Method**: Invoke lead with "Research X and report findings". Check if `.scratch/research/` file is created with correct template sections.
**Effort**: 0.5 session | **Priority**: P2

### E12: Handoff Round-Trip
**Goal**: Can a new session continue from a handoff without re-discovery?
**Method**:
1. Session A: do some work, invoke @handoff
2. Session B: invoke @read-handoff, verify it orients correctly and identifies next steps
**Metrics**: Does session B identify the correct next step without reading files session A read?
**Effort**: 0.5 session | **Priority**: P2

### E13: Init Workflow E2E
**Goal**: Does `@init-project` produce a working deployment on a real project?
**Method**: Clone a small OSS project, run init, verify all generated files are valid and the agents can be invoked.
**Effort**: 0.5 session | **Priority**: P2

### E14: Cross-Crew Handoff
**Goal**: Can work flow between crews (e.g., bugfix crew finds infra issue → infrastructure crew)?
**Method**: Give bugfix crew a task that requires infrastructure work. Verify it escalates or suggests handoff rather than attempting infra work itself.
**Effort**: 0.5 session | **Priority**: P3

### E15: Cross-Skill Link Activation
**Goal**: Does referencing a failing skill from a reliably-activating skill cause the failing skill to load?
**Method**: Modify planning-cycles to reference prototype-protocol via markdown link. Run tasks that activate planning-cycles and check if prototype-protocol also loads.
**Conditions**: baseline (no link), treatment A (relative markdown link), treatment B (inline summary), treatment C (companion file).
**Metrics**: activation rate for referenced skill, token usage delta.
**Effort**: 1 session | **Priority**: P1

### E16: Description Rewriting vs Eager Loading
**Goal**: Can we fix the 3 failing skills (diagrams 0%, ai-generation-hygiene 20%, verification-protocol 40%) without eager-loading?
**Method**: Test 3 conditions per skill: rewritten description, cross-linked from host skill (if E15 passes), eager-loaded as steering.
**Metrics**: activation rate, false positive rate, token usage.
**Effort**: 1 session | **Priority**: P1 (after E15)

## Priority Order

| Priority | Experiments | Sessions |
|----------|------------|:--------:|
| P1 | E7 ✅, E15 (cross-skill linking), E16 (description rewriting) | 2 |
| P1 | E8 (multi-agent), E9 (crew E2E) | 2 |
| P2 | E10 (eager-context), E11 (research-output), E12 (handoff), E13 (init) | 2.5 |
| P3 | E14 (cross-crew) | 0.5 |
| **Total** | | **7** |

## Relationship to Phase 10

These experiments ARE Phase 10 (end-to-end validation). Running E8, E9, and E13 on a real project constitutes the E2E validation we planned. The other experiments fill coverage gaps identified during the build.
