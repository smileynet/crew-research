# PoC Workflow — Cheatsheet

## Quick Reference

```
Understand → Research → Design → Plan → Implement → Validate
    │            │          │        │         │          │
 summary    .scratch/   decisions  plan    code+deploy  e2e test
 requirements  synthesis  (grill)   tasks   commit each  findings
```

## Kickoff Commands

```
# Phase 0: Understand
"Review [background material] and create summary.md + requirements.md"

# Phase 1: Research
"Create research-topics.md, then dispatch parallel research per topic"

# Phase 1b: Synthesize
"Synthesize findings into research-synthesis.md. Propose spikes."

# Phase 2: Design
"Interrogate the plan — one question at a time, research before recommending"

# Phase 3: Plan
"Write proposal-plan.md with architecture, specs, task graph, and spike ordering"

# Phase 4: Implement
"Create task list for first phase. Proceed."

# Validation checkpoint (use anytime)
"Validate against the plan, document findings, update plan, continue."
```

## Parallel Execution Pattern

For research and tooling phases, dispatch subagents in parallel:

```
Step 1: Research (parallel) — one subagent per topic → .memory/{topic}.md
Step 2: Tooling (parallel) — one subagent per tool → .memory/tools-{name}.md
Step 3: Spikes (sequential) — each depends on prior findings
Step 4: Plan update — mark complete, refine priorities, create specs
```

## Anti-Patterns

- Asking questions with obvious answers (discover instead)
- Building before validating assumptions (spikes first)
- Patching same failure 3 times (step back, different approach)
- Keeping findings in your head (write to .memory/)
- Letting plan drift from reality (validation checkpoints)
- Over-engineering the PoC (prove the pattern, not production-ready)
