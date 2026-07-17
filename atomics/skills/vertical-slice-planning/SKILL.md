---
name: vertical-slice-planning
description: "Plan project milestones using the right methodology for your uncertainty level. Routes between spikes (learn), tracer bullets (prove architecture), and vertical slices (deliver features). Use when stuck, planning next milestone, or project has broad progress but no end-to-end path working. Trigger: plan a milestone, what should I work on next, project feels stuck, too many things to do, replan, tracer bullet."
metadata:
  type: workflow
  invocation: both
  practice: null
---

# Vertical Slice Planning

## Route by Fog Density

How much can you see toward the destination?

| What you can see | Fog density | Methodology | Output |
|-----------------|-------------|-------------|--------|
| Can't even see the first step | **Dense** | **Spike** | Throwaway code/notes, time-boxed |
| See the first step, not the end | **Partial** | **Tracer Bullet** | Minimal end-to-end production code |
| Path is clear, need to walk it | **Clear** | **Vertical Slice** | One complete feature through all layers |

If unsure: default to **tracer bullet** — it proves the path while producing kept code.

**The fog clears as you resolve:** Each spike clears fog for a tracer bullet. Each tracer bullet clears fog for vertical slices. Don't skip levels — dense fog needs a spike, not a slice.

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

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| "Get everything working" | Pick ONE path through all layers |
| Horizontal progress (more tools, no integration) | Tracer bullet forces integration |
| Research without a failing test | Spike must answer a yes/no question |
| Stale plan ("30 min" for multi-session tasks) | Rewrite plan from current state |

## Plan Hygiene

- **Two-session rule:** no measurable progress in 2 sessions → stop and try differently.
- **Session output rule:** every session produces at least one of: a new failing test (demonstrates a gap), a previously-failing test now passing (demonstrates progress), or a plan rewrite (acknowledges reality changed).

## After Choosing Methodology

Once you've chosen spike, tracer bullet, or vertical slice — use `/ticket-planning` to break the work into individual tickets with blocking edges. Each ticket becomes one unit of work sized to a single session.
