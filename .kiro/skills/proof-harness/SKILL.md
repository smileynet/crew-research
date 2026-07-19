---
name: proof-harness
description: "Run and interpret crew-research platform proofs — run.sh adapter proofs (A/C/G series), run-proof.sh subagent reliability proofs (S series), result reading. Use when validating tool adapter behavior, testing skill discovery/isolation, or checking platform assumptions. Trigger: run proofs, proof harness, adapter proof, A-series, S-series, platform assumption, skill discovery test, subagent isolation."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Proof Harness

Validates platform assumptions about how AI tools deliver context (eager files, skill discovery, isolation). Two runners under `tools/proofs/harness/`.

## Adapter proofs — `run.sh`

```bash
bash tools/proofs/harness/run.sh --adapter kiro-cli --all
bash tools/proofs/harness/run.sh --adapter kiro-cli --definition A4-file-resource-always-loaded
bash tools/proofs/harness/run.sh --adapter codex --definition C1-agents-skills-discovery
```

Proof ID series map to tools: `A*` kiro-cli, `C*` codex, `G*` agy. Definitions in `tools/proofs/definitions/`, adapters (deployment configs per tool) in `tools/proofs/adapters/`.

## Subagent reliability proofs — `run-proof.sh`

```bash
bash tools/proofs/harness/run-proof.sh --proof S1 [--tool kiro-cli|codex|agy|crush|all] [--timeout 180]
```

`--tool all` auto-detects via `command -v` — **PATH presence ≠ model access**. On machines where crush/agy are installed but have no access (this machine, 2026-07-19), those legs produce timeouts/empty output, not meaningful failures. Run with an explicit `--tool` you know works, or treat no-access legs as SKIP when reading results (access probes are ticket 29).

## Reading results

- Results land in `tools/proofs/results/proof-{ID}-{timestamp}/` (gitignored, like eval results)
- A proof FAIL means the platform assumption is wrong — update the assumption doc (`.memory/specs/proof-harness.md`, tool-limitations references), don't "fix" the proof to pass
- Empty/timeout output from a tool leg = access or invocation problem, not evidence about the assumption — verify the tool works standalone before recording a verdict

## When to run

- After a tool version bump (kiro-cli/codex/agy/crush) — assumptions drift across versions
- Before relying on a platform behavior in a skill or steering rule (cite the proof ID)
- When an eval behaves as if context isn't loading — proofs isolate delivery from content

## Relationship to evals

Proofs test the PLATFORM (does the tool load skills at all?); evals test CONTENT (does this skill change behavior?). A failing eval with `activation_rate: 0` might be a platform problem — run the matching discovery proof before editing the skill.
