# crew-research

Monorepo of independent tools for building consistent, reusable behavioral modules across AI coding tools (kiro-cli, Claude Code, Codex, Pi).

## What It Does

- **Skills**: Portable, on-demand knowledge packs that improve agent behavior. Write once, deploy to any tool.
- **Compositions**: Agent archetypes and crew patterns that assemble skills into multi-agent workflows.
- **Generator**: Composes modules into tool-specific deployments from a single source of truth.
- **Eval harness**: Proves skills add value via dual-run comparison (with/without skill, scored by LLM judge).

## Quick Start

```bash
# Validate everything
mise run validate

# Generate a deployment
mise run generate -- --tool kiro-cli --output ./deploy

# Initialize a new project with workspace conventions
mise run init -- --project ~/code/myproject --crews general --tool kiro-cli

# Run evals
mise run eval
```

## Project Structure

```
atomics/          Skills, eager-context, eval definitions
compositions/     Agent archetypes, crew patterns, workspace conventions
tools/            Generator, eval harness, proof harness, lint
docs/             Plan, specs, practices (human-readable research)
resources/        Symlinked reference repos (read-only)
```

## Requirements

- `yq` (YAML processing)
- `kiro-cli` 2.3.0+ (agent runtime)
- `mise` (task runner, optional)

## Documentation

- `docs/plan.md` — current plan and phase definitions
- `docs/specs/` — technical specifications
- `docs/practices/` — research findings and experiment results
- `tools/evals/README.md` — eval harness usage
