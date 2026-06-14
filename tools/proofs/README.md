# Proofs

Validates that tool adapters correctly deliver context to agents (eager files loaded, skills activated, isolation maintained).

## Commands

```bash
# Run all proofs against kiro-cli
./harness/run.sh --adapter kiro-cli --all

# Run a specific proof
./harness/run.sh --adapter kiro-cli --definition A4-file-resource-always-loaded

# Codex proofs (manual — see definitions for steps)
./harness/run.sh --adapter codex --definition C1-agents-skills-discovery
```

## Structure

| Directory | Purpose |
|-----------|---------|
| `adapters/` | Tool-specific deployment configs (kiro-cli, codex, claude-code) |
| `definitions/` | Proof definitions (what to test) |
| `harness/` | Runner script |
| `results/` | Timestamped proof run outputs |

## Proof IDs

### kiro-cli (A-series)

| ID | Assumption |
|----|-----------|
| A1 | Custom agents do NOT inherit steering automatically |
| A3 | Skills NOT loaded for unrelated queries |
| A4 | Eager context is always loaded |
| A5 | Subagents get their own config, not parent's |

### Codex (C-series)

| ID | Assumption |
|----|-----------|
| C1 | Skills discovered from `~/.agents/skills/` (USER scope) |
| C2 | `~/.codex/AGENTS.md` loaded as global instructions |
| C3 | Skill body NOT loaded until activated (progressive disclosure) |
| C4 | Project skills discovered from `.agents/skills/` (REPO scope) |

### Antigravity CLI (G-series)

| ID | Assumption |
|----|-----------|
| G1 | Workspace skills discovered from `.agents/skills/` |
| G2 | `AGENTS.md` loaded from project root into session context |
| G3 | `GEMINI.md` overrides `AGENTS.md` when both present |
| G4 | Skills NOT loaded for unrelated queries |
| G5 | `~/.gemini/GEMINI.md` loaded as global context |

## Adding Proofs

1. Create `definitions/{ID}-{slug}.yaml` following existing patterns
2. Include `manual_steps` for tools without automated harness support
3. Run and record results in `results/{adapter}/`
