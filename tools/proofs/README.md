# Proofs

Validates that tool adapters correctly deliver context to agents (eager files loaded, skills activated, isolation maintained).

## Commands

```bash
# Run all proofs against kiro-cli
./harness/run.sh --adapter kiro-cli --all

# Run a specific proof
./harness/run.sh --adapter kiro-cli --definition A4-file-resource-always-loaded
```

## Structure

| Directory | Purpose |
|-----------|---------|
| `adapters/` | Tool-specific deployment configs (kiro-cli, claude-code) |
| `definitions/` | Proof definitions (what to test) |
| `harness/` | Runner script |
| `results/` | Timestamped proof run outputs |
