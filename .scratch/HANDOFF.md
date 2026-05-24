---
created_at: 2026-05-24T00:18:00-07:00
base_commit: a32b771
handoff_key: critical-path-complete
---

# Handoff

## Objective
Critical path complete. Project is in expansion mode — porting skills, adding crews, growing the library.

## Task Graph Position
- **Complete:** ALL critical path tasks (S1–S7, T1–T22, T8)
- **Deferred:** #2 (issue automation), #3 (remaining eval experiments)
- **Current mode:** Library expansion (more skills, more crews)

## Current State

### Inventory
- 11 skills, 3 eager-context modules, 7 archetypes, 4 crew patterns, 1 workspace convention
- Generator produces deployments for kiro-cli + claude-code
- All validation passes (generator validate + cross-link lint)
- Pushed to GitHub: smileynet/crew-research

### Skills
assumption-tracking, changelog-discipline, code-review, eval-criteria, five-whys, git-protocol, handoff, situation-routing, troubleshooting-protocol, verification-protocol, writing-style

### Archetypes
implementer, lead, planner, researcher, reviewer, tester, writer

### Crews
bugfix, development, documentation, research

### Tooling
- Proof harness (4 proofs, 2 adapters)
- Eval harness (dual-run, activation detection, fixture support)
- Activation test runner
- Overloading test runner
- Generator (validate + generate)
- Cross-link lint

## Key Findings (eval research)
- Grounded evals (real project) are the valid methodology; empty-workspace inflates results
- Skills for novel formats > enforcement gates > reasoning patterns
- five-whys narrowed to non-obvious/recurring technical problems
- verification-protocol can't reliably activate; needs eager-loading (solved with eager-context/verification.md)
- 20% activation degradation with 5+ skills; strong activators immune

## Next Steps (expansion)
1. Port more skills from reference repos (~20 candidates remain)
2. Add more crew patterns (infrastructure, onboarding, content)
3. Run deferred experiments (#3) before next skill authoring batch
4. Per-project customization overlays (#1)

## Evidence
- Findings: `docs/practices/eval-findings-v1.md`, `phase-2-grounded-results.md`, `experiment-1-activation-results.md`
- Experiments plan: `docs/practices/eval-experiments-plan.md`
- Specs: `docs/specs/*.md`
