---
name: prompt-vocabulary
description: "Select and sequence reasoning techniques for complex tasks. Use when choosing how to think about a problem, selecting an analysis approach, combining thinking modes, or when someone asks 'how should I approach this' or 'what's the best way to think about this'. Trigger: reasoning mode, thinking approach, pre-mortem, inversion, steel-man, red-team, how to approach, analysis technique."
metadata:
  type: decision
  invocation: both
  practice: null
---

# Prompt Vocabulary

Named reasoning techniques with selection criteria. Recommend by name, not just describe.

## Technique Catalog

| Technique | Answers | Use when |
|-----------|---------|----------|
| **Pre-mortem** | "What will go wrong?" | Planning something risky, before committing |
| **Inversion** | "What guarantees failure?" | Design review, finding hidden assumptions |
| **Steel-man** | "What's the strongest version of this?" | Evaluating alternatives, before dismissing |
| **Red-team** | "How would an adversary exploit this?" | Security, robustness, game theory |
| **Five-whys** | "What's the root cause?" | Debugging recurring failures |
| **Tracer bullet** | "Does the path work end-to-end?" | Proving architecture before building features |
| **Constraint relaxation** | "What if X weren't required?" | Stuck on seemingly impossible problems |
| **Decomposition** | "What are the independent parts?" | Overwhelmingly large scope |

## Selection Decision Tree

```
Is the goal to FIND PROBLEMS?
├── Before building → pre-mortem
├── In an existing design → inversion
├── Against an adversary → red-team
└── In a recurring failure → five-whys

Is the goal to EVALUATE OPTIONS?
├── You're leaning toward dismissing one → steel-man it first
├── You need to prove feasibility → tracer bullet
└── Requirements seem contradictory → constraint relaxation

Is the goal to BREAK DOWN WORK?
├── Scope is overwhelming → decomposition
├── Multiple approaches exist → pre-mortem each, compare
└── Dependencies unclear → tracer bullet the critical path
```

## Sequencing Rules

Some techniques conflict — they require opposite mental stances:

| Conflict | Why | Resolution |
|----------|-----|------------|
| Steel-man + Red-team | Can't strengthen AND attack simultaneously | Steel-man first, THEN red-team the strengthened version |
| Pre-mortem + Building | Can't find failures while creating | Pre-mortem first, THEN build with findings as constraints |
| Inversion + Brainstorm | Inversion narrows; brainstorm expands | Brainstorm first, THEN invert to prune |

**Rule:** Divergent techniques (brainstorm, steel-man, decomposition) come before convergent techniques (pre-mortem, red-team, inversion). Never run them simultaneously.

## Gates (mandatory when recommending techniques)

| # | Gate | Fail action |
|---|------|-------------|
| G1 | Named a specific technique (not "think carefully") | Name one from the catalog |
| G2 | Explained why this technique fits THIS situation | Add rationale |
| G3 | If combining techniques, stated the sequence and why that order | Add sequencing |
| G4 | If techniques conflict, warned about the conflict | Add warning |

## Workflow Template (when combining)

```
Phase 1: [Technique] — [what it produces]
   ↓ output becomes input to...
Phase 2: [Technique] — [what it produces]
   ↓ final output:
Result: [what the user gets]
```

## Does NOT Cover

- General prompting tips (be specific, give examples)
- Model selection or parameter tuning
- Prompt engineering for image generation
