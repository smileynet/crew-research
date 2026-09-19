---
id: "166"
title: "NEW SKILL output-contract-validation: scaffold-then-validate (P1)"
status: open
blocked_by: []
spec: "rider-followups"
---

# NEW SKILL: output-contract-validation (scaffold-then-validate)

## Intent source

Rider review, plugin-creator + skill-creator (SYNTHESIS pattern #2). Proposal:
`.scratch/new-skill-proposals-from-rider.md` P1. Both skills pair a generator (writes defaults)
with a SEPARATE validator that re-checks against the real consumer schema — allow-list keys,
fail-closed on unknowns, reject `[TODO:]` stubs, contain file paths.

## Gap it fills

`script-authoring` covers writing scripts; nothing encodes the generate→independent-verify loop
for agent-produced artifacts that must clear a downstream contract (CI config, package manifest,
generated spec). This is "verify before done" as *tooling the agent runs*, not self-inspection.

## What to build

A protocol skill `atomics/skills/output-contract-validation/SKILL.md`. Core rules:
1. Generator writes known-good defaults.
2. A SEPARATE check re-validates against the consumer's schema (not the generator's assumptions).
3. Fail-closed on unknown fields (allow-list, not deny-list).
4. Reject placeholder stubs (`[TODO:]`, `<...>`, `changeme`).
5. Contain file paths (no `..`, no absolute, no escaping symlink).

Apply skill-authoring gates: front-load triggers; success-path caveats inline (G4d); single
concern; declare scope.

## Acceptance criteria

- [ ] `output-contract-validation/SKILL.md` authored, passes all skill-authoring Creation Gates (G0-G5 + G4d)
- [ ] Added to an appropriate tier or project-level composition (per its scope)
- [ ] Activation eval authored + run: triggers on scaffolding/validation prompts, quiet on neighbors (TPR≥0.5, FPR≤0.2 via the fixed detector — ticket 160)
- [ ] Behavior eval authored + run: with-skill correctly runs a separate validator + fails closed, vs baseline (no false-clean regression)
- [ ] `mise run validate` + `mise run lint` pass; `mise run generate -- kiro-cli` clean

## Out of scope

- Vendoring a specific validator tool (the skill is the protocol; tools are per-project)

## Note

New skill → goes through the full evidence loop (activation + behavior eval) before it's trusted,
per this thread's "skills that work well with agents" standard.
