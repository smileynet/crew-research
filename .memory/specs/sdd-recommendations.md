---
type: specification
title: "SDD Reference Exploration — Recommendations"
---

# SDD Reference Exploration — Recommendations

## Context

Explored 6 repos (spec-kit, OpenSpec, BMAD, planning-with-files, claude-task-master, agentic-delivery-os) to inform enhancements to crew-research's `spec-driven-development` skill and broader planning workflow.

## What crew-research already does well

- **Skill-based delivery** — portable, tool-agnostic, no runtime dependencies
- **Scale-adaptive depth** — already in spec-driven-development skill
- **Eval harness** — none of the 6 repos have behavioral measurement (our differentiator)
- **Progressive loading** — avoids BMAD's 200KB+ context dumps
- **Clean separation** — steering (always-on) vs skills (on-demand) vs specs (per-project)

## What to adopt (high confidence)

### 1. Artifact DAG with explicit dependencies
**Source:** OpenSpec, Spec Kit

Our `spec-driven-development` skill lists phases linearly. Add explicit dependency declarations so the agent knows what blocks what:

```yaml
# In PLAN.md or .specs/
artifacts:
  proposal: {status: accepted}
  spec-auth: {requires: [proposal], status: draft}
  spec-api: {requires: [proposal], status: draft}
  design: {requires: [spec-auth, spec-api]}
  tasks: {requires: [design]}
```

**Why:** Enables parallel work identification and prevents agents from starting tasks whose dependencies aren't met.

### 2. Complexity scoring before spec depth
**Source:** claude-task-master, BMAD

Before writing a spec, have the agent assess complexity (1-5) to calibrate how much ceremony to apply:

| Score | Depth | Example |
|-------|-------|---------|
| 1 | No spec | Fix typo, update config |
| 2 | Inline in PLAN.md | Single-function change |
| 3 | Light spec (what + validation only) | New API endpoint |
| 4 | Full spec | Multi-component feature |
| 5 | Full spec + design doc + prototype | New system/architecture |

**Why:** Prevents over-planning small changes and under-planning complex ones. The current skill has a table but doesn't instruct the agent to score first.

### 3. Living spec reconciliation
**Source:** agentic-delivery-os

After implementation, reconcile the spec with what was actually built. Add a "Reconcile" step to the lifecycle:

```
Draft → Accepted → Implemented → Reconciled → Validated
```

Reconciliation = update spec to match reality if implementation diverged. Prevents specs from becoming lies.

**Why:** Every other approach (PRDs, RFCs) rots because nobody updates the doc post-implementation. Making reconciliation an explicit lifecycle step forces it.

### 4. Explicit non-goals per spec
**Source:** agentic-delivery-os, Spec Kit

Add a `## Non-Goals` section to spec template. Agents without clear boundaries tend to over-deliver.

**Why:** Scopes the agent's work. "This feature does NOT handle X" prevents gold-plating and scope creep.

### 5. Clarification as a gate (not just a step)
**Source:** Spec Kit's `/speckit.clarify`

The clarification step should be a gate: don't proceed to spec writing until ambiguity is resolved. Currently our skill says "clarify" but doesn't enforce it.

Add to the skill: "If any requirement has a question mark or uses vague language ('appropriate', 'as needed', 'various'), stop and ask before proceeding."

## What to consider (medium confidence)

### 6. Step-file architecture for complex workflows
**Source:** BMAD

For multi-phase plans, break the plan into step files that load one at a time. Prevents context bloat on long implementations.

```
.specs/
  PLAN.md              # overview + task graph
  phase-1-auth.md      # current step (loaded)
  phase-2-api.md       # next step (not yet loaded)
```

**Trade-off:** More files to manage. Only worthwhile for 4+ phase projects.

### 7. Model tiering by task complexity
**Source:** agentic-delivery-os, claude-task-master

Route simple spec-following tasks to faster/cheaper models, reserve expensive models for design decisions and complex specs.

**Trade-off:** Requires multi-model support in kiro-cli. Not actionable today but worth designing for.

### 8. Party-mode design review
**Source:** BMAD

For complex specs, dispatch multiple subagents with different "perspectives" (security, performance, UX, maintainability) to review the spec before acceptance.

**Trade-off:** Token-expensive. Better suited as an optional enhancement of `/grill-with-docs`.

## What to skip

| Pattern | Why skip |
|---------|----------|
| **Named agent personas** (BMAD) | Adds ceremony without measurable improvement for single-agent workflows |
| **npm/pip distribution** (Spec Kit, BMAD) | Our shell-based init.sh is simpler and has no runtime deps |
| **Hook-driven plan re-reading** (planning-with-files) | 68% token overhead; our skill activation is cheaper |
| **30+ editor adapters** (OpenSpec, Spec Kit) | We support kiro-cli. Add others when demand exists, not speculatively |
| **Full SDLC ceremony always** (agentic-delivery-os) | No fast path = friction on small changes. Our scale-adaptive approach is better |
| **TOML config** (BMAD) | YAML is already our standard; switching adds no value |

## Immediate action items

1. **Add Non-Goals section** to spec template (trivial, high value)
2. **Add Reconciliation lifecycle state** (Draft → Accepted → Implemented → Reconciled → Validated)
3. **Add complexity scoring instruction** ("Before writing a spec, assess complexity 1-5")
4. **Strengthen clarification gate** ("Do not proceed if vague language remains")
5. **Document artifact DAG pattern** in references/ companion file for complex projects

## Long-term considerations

- If crew-research grows to support Claude Code / Cursor / Codex, study OpenSpec's adapter pattern
- If multi-model routing becomes available in kiro-cli, implement tiering
- Party-mode review could enhance grill-with-docs for architecture decisions
