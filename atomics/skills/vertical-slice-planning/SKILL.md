---
name: vertical-slice-planning
description: "Plan project milestones using the right methodology for your uncertainty level. Routes between spikes (learn), tracer bullets (prove architecture), and vertical slices (deliver features). Use when stuck, planning next milestone, or project has broad progress but no end-to-end path working. Trigger: plan a milestone, what should I work on next, project feels stuck, too many things to do, replan, tracer bullet."
metadata:
  type: workflow
  invocation: both
  practice: null
---

# Vertical Slice Planning

## Step 1: Assess Uncertainty

What's blocking progress?

| Signal | Methodology | Output |
|--------|-------------|--------|
| "I don't understand how X works" | **Spike** | Throwaway code/notes, time-boxed |
| "I don't know if the layers connect" | **Tracer Bullet** | Minimal end-to-end production code |
| "Architecture works, need more features" | **Vertical Slice** | One complete feature through all layers |

If unsure: default to **tracer bullet**.

---

## Spike (reduce uncertainty)

**Use when:** You don't understand a subsystem, tool, or technique well enough to plan.

- Time-box: 2-4 hours max
- Output is THROWN AWAY (or moved to `.scratch/`)
- Must answer a specific yes/no question
- End with: "Now I know X, which means we should Y"

```
SPIKE: [what you're investigating]
QUESTION: [specific yes/no question]
TIME-BOX: [hours]
SUCCESS: [what artifact proves it works]
FAILURE: [document why + alternative approach]
```

**After spike:** Define a tracer bullet or slice with the new understanding.

---

## Tracer Bullet (prove architecture)

**Use when:** Multiple layers/systems need to connect but haven't proven they work together.

Properties:
- Touches ALL layers (input → processing → output)
- Is PRODUCTION CODE (kept, not thrown away)
- Is MINIMAL (simplest possible path, completable in ~1 day)
- Proves the architecture works end-to-end
- Becomes the skeleton that features hang on

```
TRACER: [one-sentence description of minimal e2e path]
LAYERS: [list each layer it touches]
MINIMAL PATH: [simplest possible route through all layers]
SUCCESS: [concrete artifact that proves it works]
KEEP: Yes — this becomes the foundation
```

**After tracer bullet:** Architecture is proven. Expand with vertical slices.

---

## Vertical Slice (deliver features)

**Use when:** Architecture is proven and you need to fill in features incrementally.

```
SLICE: [one-sentence description]
INPUT: [exact starting state]
EXPECTED: [exact output — testable assertion]
SYSTEMS REQUIRED: [minimum subsystems that must work]
```

### Expansion Pattern

Each slice adds exactly ONE new capability. If it breaks, you know what caused it.

---

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| "Get everything working" | Pick ONE path through all layers |
| Horizontal progress (more tools, no integration) | Tracer bullet forces integration |
| Research without a failing test | Spike must answer a yes/no question |
| Stale plan ("30 min" for multi-session tasks) | Rewrite plan from current state |

## Plan Hygiene

### Two-Session Rule
No measurable progress in 2 sessions → stop and try differently.

### Session Output Rule
Every session produces at least one of:
- A new failing test (demonstrates a gap)
- A previously-failing test now passing (demonstrates progress)
- A plan rewrite (acknowledges reality changed)
