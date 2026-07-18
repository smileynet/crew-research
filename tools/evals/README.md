# Eval Harness

Behavioral evals for crew-research skills. Two harnesses:

| Harness | Purpose | Definitions |
|---------|---------|-------------|
| `harness/run.sh` | Judged dual-run evals (skill vs baseline, LLM consensus scoring) | `definitions/*.yaml` with `tasks[].criteria` |
| `harness/run-activation.sh` | Activation regression (does the skill load when triggered?) | `definitions/activation-*.yaml` with `tasks[].expect_activation` |

```bash
mise run eval                          # all dual-run evals, 3 trials
mise run eval:one -- <definition>      # single eval by name (no .yaml)
mise run eval:activation               # activation suite
```

Always run in background (see `.kiro/steering/eval-execution.md`): a full suite takes hours.

## Dual-Run Definition Schema (run.sh)

```yaml
id: my-skill-effectiveness            # IMMUTABLE — set once at creation, survives renames.
                                      # Longitudinal comparison keys on id, never name
                                      # (2026-07-15→17: only 12/35 defs comparable after renames).
name: my-skill-effectiveness          # required, matches filename (renameable)
description: "What this measures"     # required
known_gap: "model-family — why"       # optional — documents a known cross-model failure so
                                      # it doesn't read as a fresh regression each run.
                                      # Current: 3 defs fail/flip under codex-family judging.
fixture: defu                          # optional — fixtures/{name}.yaml (git-clone workspace)
skill: my-skill                        # legacy shorthand — prefer conditions:

conditions:                            # 2 conditions = comparison; 1 = threshold-only
  with-skill:
    skills: [my-skill]                 # deployed to workdir .kiro/skills/ (+references/)
    steering:                          # optional — files FROM tools/evals/steering/
      - my-steering.md                 #   MUST end .md and exist there
  baseline:
    skills: []
    steering: []

tasks:                                 # 1+ tasks; each runs trials× per condition
  - name: descriptive-slug             # optional
    input: |                           # REQUIRED — the single prompt sent to the agent
      Task text...
    criteria: |                        # REQUIRED — judge rubric
      PRIMARY: The one behavior being measured.
      AUTOMATIC FAIL (score 1): ...
      Score 3: ...
      Score 4: ...
      BONUS (score 5): ...
    ideal: "optional reference answer"

trials: 3                              # runs per task per condition
threshold: 4                           # with-skill avg must reach this
delta_threshold: 0.5                   # with-skill minus baseline must reach this
                                       #   variance-reduction skills: use -0.5
timeout: 120                           # seconds per session
tags: [category, skill-name]
```

### Unsupported (will silently break — input resolves to null)

- `turns:` arrays / `mode: multi-turn` — no multi-turn support; embed prior turns in a single `input`
- `steering_override:` — inline steering text; put a file in `tools/evals/steering/` instead
- `prompts:` — old field name; use `tasks:`

### Isolation

kiro-cli sessions run with `KIRO_HOME=$workdir/.kiro` — conditions see ONLY their declared
skills/steering, never the global `~/.kiro/`. Every workdir gets empty `.kiro/{skills,steering}`
so the baseline is truly bare. Consequence: evals needing external state (e.g. the real recall
DB at `~/.recall/`) can't run isolated — see `definitions/retired/recall-cross-session-continuity.yaml`.

### Judging

4-model consensus (claude-opus + codex + crush + agy run in parallel; median score).
Session behavior (tool calls, retries) is extracted and shown to the judge; definitions can add
`log_analysis.penalties` (max_tool_calls, max_retries) for hard score deductions.

## Activation Definition Schema (run-activation.sh)

```yaml
name: activation-my-skill
skill: my-skill
tasks:
  - input: "Prompt that SHOULD trigger the skill"
    expect_activation: true
  - input: "Prompt that should NOT trigger it"
    expect_activation: false
```

Scored as TP/FP/TN/FN — no LLM judge, no threshold field (a `threshold:` key is ignored).

## Directory Layout

```
definitions/           # active eval definitions
definitions/retired/   # kept for history; excluded from --all
fixtures/              # workspace fixtures (git clone + install + injected files)
steering/              # steering files referenced by definitions' conditions
harness/               # run.sh, run-activation.sh, run-experiment.sh, judges
results/               # timestamped run output (gitignored)
experiments/           # multi-condition experiment configs
```

## Writing Good Criteria

See the `eval-criteria` skill. Non-negotiables: a PRIMARY clause naming the single behavior
measured, an AUTOMATIC FAIL clause, and anchored scores (what 3 vs 4 vs 5 looks like).
One signal per eval — multi-purpose evals (see retired part-b-enrichments) can't attribute failures.
