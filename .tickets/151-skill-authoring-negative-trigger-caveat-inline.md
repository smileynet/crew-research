---
id: "151"
title: "skill-authoring: positive-first activation guidance + happy-path caveats inline (P1+P2)"
status: open
blocked_by: []
spec: "rider-skill-updates"
---

# skill-authoring: positive-first activation guidance + happy-path caveats inline (P1+P2)

## Intent source

Analysis of JetBrains Rider AIA skills (`.references/rider-skills/`, 2026-09-17) →
proposals hardened via research + codebase review. Full proposal:
`.scratch/skill-update-exploration/PROPOSALS.md` (Rev 2, P1 + P2). Evidence:
`.scratch/proposal-research/{negative-triggers,progressive-disclosure}.md`,
`.scratch/proposal-codebase/{activation-evals,progressive-disclosure}.md`.
(Regenerate from `.references/rider-skills/` if scratch is cleared.)

## Context

Two changes to the SAME file (`atomics/skills/skill-authoring/SKILL.md`), both from the Rider review:

**P1 — activation guidance.** Rider skills (imagegen, openai-docs, refactoring-code,
debugging-code) put "Do not use when…" in the description. Research CHALLENGED this:
Anthropic [L4] is silent on exclusion clauses and prescribes positive specificity;
a Microsoft production paper [L1] shows discriminative POSITIVE rewriting is the lever
and genuine overlap is unfixable by text; the one tutorial [L5] recommending exclusion
clauses measured NO FP reduction. Codebase: 0/61 skills use the pattern (novel/untested).
→ Ship the positive-first framing NOW; the negative-clause tactic stays optional +
eval-gated (see ticket 154).

**P2 — happy-path caveats inline.** Sharpest Rider defect: refactoring-code/debugging-code
gate SUCCESS-path caveats behind references loaded only on failure. Research STRONGLY
supports fixing it (Anthropic [L4]: level-3 reads are best-effort — partial reads, missed
links). Codebase conflict: a standalone new rule would duplicate Rule 4 + violate Rule 6
"one owner" → reframe as a Rule 4 SHARPENING. Precedent exists: tutorial-authoring
"Pitfall dual-storage" + "Required steps stay inline".

## What to build

P1:
1. `## Writing a Good Description`: add a positive-first + FRONT-LOAD note — front-load
   trigger keywords + "Use when" (Codex truncates over-budget listings by shortening
   descriptions; harmless elsewhere); if a skill over-fires, sharpen positively first;
   wording beats length (length is a cost knob, not quality). Genuine overlap = split, not reword.
2. Add negative clauses only as optional/secondary/eval-gated: "Not for … (see X)" MAY help
   broad-vocabulary skills but keep keywords FIRST and measure via `mise run eval:activation`
   before adopting (→ ticket 154, which first needs ≥10 negative decoys to resolve any delta).
3. Add a note that "disable implicit invocation" is NOT portable authoring guidance — it's
   tool-specific (kiro-cli has no off switch; Codex needs an `agents/openai.yaml` sidecar;
   opencode needs a `permission.skill` rule) → a per-tool deploy concern, not a description edit.
4. `## Testing Activation`: name FPR, the ≤0.2 gate, `mise run eval:activation`, and the
   ≥10-negatives caveat (5 gives a 0.20 quantum = the gate).

P2:
5. Sharpen Rule 4 (append one sentence): a caveat that applies when the workflow SUCCEEDS
   is load-bearing — keep it inline at the step it qualifies; never gate it behind a
   reference that only loads on failure/conflict/edge cases (refs are best-effort reads;
   deploy ships them as separate companion files — cite tutorial-authoring/SKILL.md:68
   "Pitfall dual-storage").
6. Add Gate G4d (references Rule 4, no new concept): success-path caveats are inline, not
   gated behind a failure/conflict reference.
7. Add one Anti-Patterns row: "Success-path caveat gated behind a branch reference".

## Acceptance criteria

- [ ] Positive-first + FRONT-LOAD-keywords note added to `## Writing a Good Description` (Codex-truncation rationale; wording-beats-length)
- [ ] Negative-clause tactic framed as optional + eval-gated (points to ticket 154), keywords-first
- [ ] Note added that "disable implicit invocation" is tool-specific (kiro-cli none / Codex sidecar / opencode permission) — a deploy concern, not authoring guidance
- [ ] `## Testing Activation` names FPR, the ≤0.2 gate, `mise run eval:activation`, and the ≥10-negatives caveat
- [ ] Rule 4 sharpened with the happy-path-caveat sentence (cross-refs tutorial-authoring/SKILL.md:68)
- [ ] Gate G4d added; one Anti-Patterns row added — both point back to Rule 4 (no Rule 6 duplication)
- [ ] `mise run validate` + `mise run generate -- kiro-cli` clean; skill still reads as one coherent file (note: `mise run lint` has a pre-existing unrelated dispatch-codex-review failure)

## Out of scope

- Adopting negative clauses as STANDARD practice — that requires ticket 154's eval result first
- Editing any other skill's description
- Rewriting existing skill descriptions to add exclusion clauses (guidance only, not a sweep)

## Rejected alternatives

- Standalone "Rule 8" for happy-path caveats — rejected (duplicates Rule 4, violates Rule 6
  one-owner). Kept as a Rule 4 sharpening + gate + anti-pattern.
- "Add 'Do not use when' to descriptions" as blanket guidance — rejected (first-party silent,
  sole recommending source measured no benefit, truncation risk). Optional + eval-gated instead.

## Revisit trigger

If ticket 154's eval shows a real FPR drop from a negative clause (TPR held), promote the
negative-clause tactic from "optional/unproven" to "recommended for broad-vocabulary skills".

- [ ] TBD
