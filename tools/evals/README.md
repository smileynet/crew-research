# Eval Toolchain

## Quick Reference

```bash
# Validate compositions (always run first)
tools/generator/generate.sh validate

# Run a single dual-run eval (quality comparison)
tools/evals/harness/run.sh --definition <name> --trials 3

# Run all dual-run evals
tools/evals/harness/run.sh --all --trials 3

# Test skill activation reliability
tools/evals/harness/run-activation.sh --all

# Run a multi-condition experiment
tools/evals/harness/run-experiment.sh --experiment <name> --trials 3 --fixture defu --timeout 120

# Extract metrics from a past session
tools/evals/harness/extract-metrics.sh /tmp/eval-workspace-path

# Check activation for a specific workspace
tools/evals/harness/check-activation.sh /tmp/workspace skill-name

# Cross-link lint
tools/lint/check-crosslinks.sh
```

## Experiment Workflow

1. Define experiment in `tools/evals/experiments/<name>.yaml`
2. Run: `tools/evals/harness/run-experiment.sh --experiment <name> --trials 3 --fixture defu`
3. Results land in `tools/evals/results/<name>-<timestamp>/`
4. Review `summary.json` and `experiment.jsonl`

## Experiment Definition Format

```yaml
question: "What are we trying to learn?"
experiment: slug-name
category: methodology

conditions:
  - name: baseline
    skills: []
  - name: with-skill
    skills: [skill-name]

tasks:
  - name: task-slug
    input: "The prompt sent to the agent"

metrics: [total_tokens, context_usage_pct, phase_coherence]

acceptance_criteria: |
  - What constitutes a meaningful finding
```

## Available Experiments

| Experiment | Question | Conditions | Tasks |
|-----------|----------|:----------:|:-----:|
| token-efficiency | Is quality worth the token cost? | 4 | 3 |
| skill-interference | Do multiple skills degrade each other? | 5 | 3 |
| process-tracing | Does the skill change HOW the agent works? | 3 | 3 |

## Data Flow

```
Experiment Definition (YAML)
    ↓
run-experiment.sh (orchestrates conditions × tasks × trials)
    ↓
kiro-cli invocation (isolated temp dir with skills deployed)
    ↓
sqlite conversation data (stored by kiro-cli)
    ↓
extract-metrics.sh (pulls tokens, tool calls, phases)
    ↓
experiment.jsonl + summary.json (results)
```
