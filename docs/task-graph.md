# Task Graph

## Legend

- `→` = depends on (must complete before)
- `||` = can run in parallel
- `[spike]` = research/spike needed before implementation
- `[blocked]` = blocked by an open question

## Phase 0: Spikes & Research

These must resolve before the main work begins.

### S1: Spike — kiro-cli prompt/skill invocation parity
**Question:** kiro-cli now supports skills as slash commands (`/skill-name`). Does this fully replace `.kiro/prompts/`, or do prompts still offer capabilities skills don't (e.g., argument handling, model switching)?
**Method:** Test with kiro-cli current version. Create a skill with `invocation: user-only` equivalent and verify it behaves identically to a prompt.
**Acceptance:** Documented matrix of what prompts can do vs skills-as-slash-commands in kiro-cli.

### S2: Spike — Claude Code skill frontmatter compatibility
**Question:** Our spec adds `type`, `invocation`, and `practice` frontmatter fields. Does Claude Code ignore unknown frontmatter fields, or does it error?
**Method:** Deploy a skill with extra frontmatter to Claude Code, verify it loads and activates correctly.
**Acceptance:** Confirmed that our extended frontmatter is safe across tools.

### S3: Spike — Codex/Pi skill format validation
**Question:** Do Codex and Pi follow the Agent Skills standard strictly? What frontmatter fields do they require/reject?
**Method:** Deploy test skills to each tool, verify loading behavior.
**Acceptance:** Compatibility matrix documenting which frontmatter fields each tool supports.

### S4: Spike — Eval harness judge model selection
**Question:** Which judge model + configuration produces the most reliable scoring for our eval types? What's the cost/reliability tradeoff?
**Method:** Run 10 representative evals with 3 different judge models, compare score variance and agreement with human judgment.
**Acceptance:** Recommended judge configuration with documented reliability metrics.

### S5: Spike — Per-project customization design (Issue #1)
**Question:** How do project-specific overlays work? Override files? Inheritance? Parameterized templates?
**Method:** Research CSS cascade, Helm values, Terraform overrides. Prototype 2-3 approaches with a concrete example (Godot troubleshooting overlay).
**Acceptance:** ADR with chosen approach and one working example.

---

## Phase 1: Foundation

```
S1 ─┐
S2 ─┤
S3 ─┴→ T1: Scaffold monorepo directory structure
         │
         ├→ T2: Implement tool adapter format + kiro-cli adapter
         │    │
         │    ├→ T3: Implement proof harness (isolation, invocation, grading)
         │    │    │
         │    │    └→ T4: Port existing assumption proofs to declarative format
         │    │         │
         │    │         └→ T5: Run proofs against kiro-cli, record baseline
         │    │
         │    └→ T6: Write Claude Code adapter
         │         │
         │         └→ T7: Run proofs against Claude Code
         │
         └→ T8: Implement lint script (cross-link validation)
```

### Tasks

| ID | Task | Depends On | Effort |
|----|------|-----------|--------|
| T1 | Scaffold `atomics/`, `compositions/`, `tools/`, `docs/specs/`, `docs/practices/` | S1, S2, S3 | Small |
| T2 | Implement adapter YAML schema + kiro-cli adapter | T1 | Medium |
| T3 | Implement proof harness (bash: mktemp, deploy, invoke, grade) | T2 | Medium |
| T4 | Port A1-A7 proofs from agent-crews to declarative YAML format | T3 | Small |
| T5 | Run proof suite against kiro-cli, store baseline results | T4 | Small |
| T6 | Write Claude Code adapter | T2 | Medium |
| T7 | Run proof suite against Claude Code | T4, T6 | Small |
| T8 | Implement cross-link lint script | T1 | Small |

---

## Phase 2: Eval Harness

```
T5 ─┐
S4 ─┴→ T9: Implement eval harness (judge invocation, scoring pipeline)
          │
          ├→ T10: Implement dual-run mode (with/without skill comparison)
          │
          └→ T11: Port representative evals from agent-crews to declarative format
               │
               └→ T12: Run eval suite, validate scoring reliability
```

| ID | Task | Depends On | Effort |
|----|------|-----------|--------|
| T9 | Implement eval harness (isolation, judge, scoring) | T5, S4 | Large |
| T10 | Add dual-run mode (baseline comparison) | T9 | Medium |
| T11 | Port 10-15 representative evals to new format | T9 | Medium |
| T12 | Validate scoring reliability (3+ runs, check variance) | T11 | Small |

---

## Phase 3: Module Authoring

```
T8 ──┐
T12 ─┴→ T13: Author first 5 skills from reference repos
          │     (one per type: protocol, reasoning-mode, reference, decision, process)
          │
          ├→ T14: Author first 3 eager-context modules
          │     (workspace, verification, signaling)
          │
          ├→ T15: Write first 2 practices with cross-linked skills
          │
          └→ T16: Run dual-run evals on authored skills (prove value)
               │
               └→ T17: Iterate on skills that don't show delta over baseline
```

| ID | Task | Depends On | Effort |
|----|------|-----------|--------|
| T13 | Author 5 representative skills (one per type) | T8, T12 | Medium |
| T14 | Author 3 eager-context modules | T8 | Small |
| T15 | Write 2 practices with cross-linked skills | T13 | Medium |
| T16 | Run dual-run evals on authored skills | T13, T10 | Small |
| T17 | Iterate on skills that fail delta threshold | T16 | Medium |

---

## Phase 4: Compositions

```
T13 ─┐
T14 ─┴→ T18: Author first agent archetype (researcher)
          │
          ├→ T19: Author first crew pattern (research crew)
          │
          └→ T20: Author workspace convention (standard)
               │
               └→ T21: Validate compositions resolve correctly (all refs exist)
```

| ID | Task | Depends On | Effort |
|----|------|-----------|--------|
| T18 | Author researcher agent archetype | T13, T14 | Medium |
| T19 | Author research crew pattern | T18 | Medium |
| T20 | Author standard workspace convention | T14 | Small |
| T21 | Validate all composition references resolve | T18, T19, T20 | Small |

---

## Phase 5: Generator

```
S5 ─┐
T21 ┴→ T22: Implement generator (resolve refs, emit per-tool output)
          │
          ├→ T23: Generate kiro-cli deployment from compositions
          │
          ├→ T24: Generate Claude Code deployment from compositions
          │
          └→ T25: End-to-end test: generate → deploy → run proofs → run evals
```

| ID | Task | Depends On | Effort |
|----|------|-----------|--------|
| T22 | Implement generator core (resolve, validate, emit) | S5, T21 | Large |
| T23 | Generate kiro-cli deployment | T22 | Medium |
| T24 | Generate Claude Code deployment | T22 | Medium |
| T25 | End-to-end validation | T23, T24 | Medium |

---

## Critical Path

```
S1/S2/S3 → T1 → T2 → T3 → T4 → T5 → T9 → T10 → T13 → T16 → T18 → T22 → T25
```

Estimated: 5 spikes + 25 tasks. Spikes should complete first to de-risk the main work.

## Parallel Tracks

Once T2 is done, these can run in parallel:
- **Track A:** Proof harness (T3→T4→T5→T7)
- **Track B:** Lint tooling (T8)
- **Track C:** Claude Code adapter (T6→T7)

Once T9 is done:
- **Track D:** Dual-run mode (T10)
- **Track E:** Eval porting (T11→T12)

---

## Open Items Requiring Resolution

| Item | Blocking | Resolution Path |
|------|----------|----------------|
| kiro-cli prompt vs skill parity | T1 (layout finalization) | Spike S1 |
| Unknown frontmatter field tolerance | T13 (skill authoring) | Spike S2, S3 |
| Judge model reliability | T9 (eval harness) | Spike S4 |
| Per-project customization | T22 (generator) | Spike S5 / Issue #1 |
| Codex CLI availability/access | T6 equivalent for Codex | May need to defer Codex adapter |
| Activation rate improvement | T16 (skill value proof) | Research forced-eval hooks vs description optimization |
