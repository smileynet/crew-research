---
type: specification
title: "Skill Improvements from mattpocock Reference"
---

# Spec: Skill Improvements from mattpocock Reference

**Status:** Proposed
**Date:** 2026-07-09
**Source:** `.references/mattpocock-skills/`, `.scratch/research/mattpocock-skills-comparison.md`

---

## 1. Cheatsheet → Active Router

**Current:** 91-line table listing skills and commands. Passive reference.

**Proposed:** Rewrite as a flow map that routes users to the right skill based on their situation. Keep tables for reference, but lead with decision routing.

**Structure:**

```markdown
# Where to Start

## Main flow: idea → ship
1. Describe what you want → planning-cycles activates
2. Stress-test the plan → /grill-with-docs
3. Need research first? → /plan-prereqs
4. Write the spec → /spec-driven-development (via spec-driven-development)
5. Build → just work (code-review, testing-guide, git-protocol activate)
6. End session → /handoff

## On-ramps (something's wrong)
- Bug / failure → feedback-loop-debugging activates
- Architecture smells → /architecture-deepening (or /grill-with-docs)
- Lost context → /read-handoff
- "What did we decide?" → recall search (automatic via steering)

## Maintenance
- Weekly cleanup → /project-cleanup
- Check for drift → /project-audit
- Starting fresh → /init-project or /adopt-project
- Wrapping up → /project-winddown

## Research
- Deep-dive a reference repo → /study-reference
- Parallel topic research → /research-topics

## Tables (full reference)
[existing tables stay below the flow map]
```

**Rationale:** Users don't memorize 15 commands. They have a *situation* and need the right entry point. A router answers "where do I start?" — the most common new-user question.

**Lines:** ~100 (adds flow map above existing tables, trims some redundancy)

---

## 2. Feedback Loop Debugging — Tighten the Loop Discipline

**Current:** 62 lines. Has the 10-technique ladder (already good). Missing: the "tighten the loop" discipline and non-deterministic bug handling.

**Proposed:** Add a `references/tighten.md` with loop-tightening patterns and flaky-bug strategies.

**New: `references/tighten.md`**

```markdown
# Tighten the Loop

Treat the feedback loop as a product. Once you have ANY loop, tighten it:

## Speed
- Cache setup (don't rebuild the world each run)
- Skip unrelated init (focus on the code path)
- Narrow test scope (one assertion, not the full suite)
- Target: < 5 seconds per iteration

## Sharpness
- Assert on the SPECIFIC symptom, not "didn't crash"
- One bug per loop (separate interacting bugs)
- Output shows WHAT failed, not just THAT it failed

## Determinism
- Pin time (freeze Date.now, control clocks)
- Seed RNG (same random = same failure)
- Isolate filesystem (temp dirs, clean state)
- Freeze network (mocks, recorded fixtures)

## Non-Deterministic Bugs
Goal: raise reproduction rate until debuggable.

- Loop the trigger 100× (statistics > patience)
- Parallelise if safe (race conditions surface faster)
- Add stress (concurrent requests, memory pressure)
- Narrow timing windows (add sleeps around suspected races)
- A 50%-flake is debuggable; 1% is not — keep raising

## When You Cannot Build a Loop
Stop. List what you tried. Ask for:
1. Access to the reproducing environment
2. Captured artifact (HAR, log dump, core dump, screen recording)
3. Permission to add temporary production instrumentation

Do NOT hypothesize without a loop.
```

**Changes to SKILL.md:** Add pointer: "For loop optimization strategies, read [references/tighten.md](references/tighten.md)"

**Rationale:** The 10-technique ladder tells you HOW to build a loop. The tightening discipline tells you how to make it *good*. mattpocock's key insight: "a 30-second flaky loop is barely better than no loop."

---

## 3. Code Review — Two-Axis (Standards + Spec)

**Current:** 85 lines. Single-axis review against a generic checklist. Dispatches a subagent.

**Proposed:** Add spec-awareness axis and a Fowler-smell reference. Keep existing structure but restructure as two parallel checks.

**Changes to SKILL.md:**

Replace the "Dispatch review subagent" section with:

```markdown
### 2. Identify review sources

**Standards axis:**
- `.kiro/steering/` — project coding rules
- `CONTRIBUTING.md` or `CODING_STANDARDS.md` if they exist
- Fowler smell baseline (see [references/smells.md](references/smells.md))

**Spec axis:**
- Commit messages for issue references (#123, Closes #45)
- `.memory/specs/` — feature specs matching the branch/feature name
- `.scratch/` — active plans or grill findings
- If no spec found: skip spec axis, note "no spec available"

### 3. Dispatch two review subagents (parallel)

**Standards subagent:** "Review this diff against these coding standards. Flag violations."
**Spec subagent:** "Review this diff against this spec. Does it implement what was specified? Missing anything?"

Provide each subagent with ONLY its relevant axis. Don't give the standards reviewer the spec (it might excuse shortcuts).
```

**New: `references/smells.md`**

```markdown
# Smell Baseline (Fowler)

Apply to every diff regardless of project standards. Each is a heuristic — flag as "possible X", not a hard violation. Skip anything project tooling already enforces.

- **Mysterious Name** — name doesn't reveal purpose → rename
- **Duplicated Code** — same shape in multiple hunks → extract
- **Feature Envy** — method reaches into another object's data → move it
- **Data Clumps** — same fields travel together → bundle into a type
- **Primitive Obsession** — string/int standing in for a domain concept → give it a type
- **Repeated Switches** — same if/switch cascade recurs → polymorphism or map
- **Shotgun Surgery** — one change forces scattered edits → gather into one module
- **Speculative Generality** — abstraction for needs the spec doesn't have → delete it
- **Middle Man** — class that mostly delegates → cut it, call direct
- **Message Chains** — long a.b().c().d() navigation → hide behind one method

Repo standards override: if a documented convention endorses what a smell would flag, suppress it.
```

**Rationale:** Two-axis catches both "code is bad" and "code doesn't match intent." The spec axis catches missing features, wrong behavior, and scope creep. The smell baseline gives reviewers a shared vocabulary without requiring project-specific documentation.

---

## 4. Architecture Deepening — Design Vocabulary Reference

**Current:** 92 lines + 1 reference. Uses terms like "deep module" informally.

**Proposed:** Add `references/design-vocabulary.md` establishing the canonical terms.

**New: `references/design-vocabulary.md`**

```markdown
# Design Vocabulary

Use these terms consistently in architecture discussions. Don't substitute "component," "service," "API," or "boundary."

**Module** — anything with an interface and an implementation. Scale-agnostic: function, class, package, or tier-spanning slice.

**Interface** — everything a caller must know: type signature + invariants + ordering + error modes + performance. Not just the signature.

**Depth** — leverage at the interface. Deep = large behavior behind small interface. Shallow = interface nearly as complex as implementation (avoid).

**Seam** — a place where behavior can change without editing that place. Where the interface lives. A design decision independent of what sits behind it.

**Adapter** — a concrete thing satisfying an interface at a seam. Describes role, not substance.

**Leverage** — what callers get from depth: more capability per unit of interface learned.

**Locality** — what maintainers get from depth: change concentrates in one place.

## Tests

- **Deletion test:** would deleting this module concentrate complexity? If yes → it's deep (good). If no → it's shallow (reconsider).
- **Interface = test surface:** if you can't test the module through its interface, the interface is wrong (too narrow) or the seam is in the wrong place.
- **One adapter = hypothetical seam. Two adapters = real seam.** Don't introduce seams until the second consumer appears.
```

**Changes to SKILL.md:** Add pointer in the exploration section: "For shared design vocabulary, see [references/design-vocabulary.md](references/design-vocabulary.md)"

---

## 5. Skill Authoring — Leading Words Concept

**Current:** 91 lines. Covers format, structure, triggers. Doesn't discuss behavioral anchoring via pretrained concepts.

**Proposed:** Add `references/leading-words.md` about using compact pretrained concepts to anchor agent behavior.

**New: `references/leading-words.md`**

```markdown
# Leading Words

A leading word is a compact concept from the model's pretraining that anchors agent behavior in few tokens. It recruits priors the model already holds.

## In the skill body
Repeated use of a leading word accumulates a distributed definition. The agent reaches for the same behavior every time it encounters the word.

Examples:
- "tight" (feedback loop) — collapses "fast, deterministic, low-overhead" into one pretrained word
- "red" (test state) — converts a fuzzy "loop that detects the bug" into a binary observable
- "depth" (module design) — recruits Ousterhout's deep-module concept in one word
- "fog" (unknown scope) — recruits fog-of-war metaphor for progressive discovery

## In the description
The same word in your description anchors invocation: when the user's prompt contains the leading word, semantic matching fires more reliably.

## Finding leading words
Look for:
- Three-word phrases restated multiple times → collapse to one pretrained word
- Sentences that gesture at a concept → name the concept
- Behavioral instructions that could be a single metaphor

## Anti-pattern: invented jargon
Leading words must exist in pretraining. Invented terms (neologisms) don't recruit priors — they're just labels the agent has to learn from your text alone. Use existing concepts, not new ones.
```

---

## 6. Prototype Protocol — Branch-Picking

**Current:** 64 lines + 2 references (poc-workflow adjacent). General prototype guidelines.

**Proposed:** Add explicit branch decision at the top of the process.

**Change to SKILL.md:** Add after the current process header:

```markdown
## Pick the branch

Identify which question is being answered:

| Question type | Branch | Output |
|--------------|--------|--------|
| "Does this logic / state model feel right?" | Logic | Minimal interactive app (CLI/REPL) that pushes state through edge cases |
| "What should this look like?" | UI | Multiple visual variants, switchable, side-by-side comparison |
| "Is this technically feasible?" | Spike | Minimal proof that the path works, findings captured |

If ambiguous: backend/data context → Logic. Frontend/design context → UI. Unknown territory → Spike.
```

---

## Execution Plan

| # | Change | Effort | Risk |
|---|--------|--------|------|
| 1 | Cheatsheet → router | 30 min | Low — additive, keeps existing tables |
| 2 | feedback-loop + tighten.md | 15 min | Low — adds reference file only |
| 3 | code-review + smells.md | 25 min | Medium — restructures process section |
| 4 | architecture-deepening + vocabulary.md | 10 min | Low — adds reference file only |
| 5 | skill-authoring + leading-words.md | 10 min | Low — adds reference file only |
| 6 | prototype-protocol branch table | 5 min | Low — adds 10 lines to existing |

**Total:** ~95 min. All changes are additive (new reference files) or restructuring (existing content reorganized). No skills removed or renamed.

---

## Validation

After all changes:
1. `mise run validate` — compositions resolve
2. Spot-check: deploy to temp workspace, verify skills load
3. Optional: run activation test on code-review (description unchanged, should maintain)
