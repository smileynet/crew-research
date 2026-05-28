# Generator

Composes atomic modules and compositions into tool-specific deployments.

## Commands

```bash
# Validate all compositions (check references, schema)
./generate.sh validate

# Initialize a project with a tier
./init.sh --project ~/code/myproject --tier basic --tool kiro-cli

# Re-run to sync/update (idempotent — preserves customizations)
./init.sh --project ~/code/myproject --tier full --tool kiro-cli
```

## Scripts

| Script | Purpose |
|--------|---------|
| `generate.sh` | Validate compositions and generate tool-specific output |
| `init.sh` | Deploy a tier to a project (steering, skills, prompts, agents) |
| `catalog.sh` | List available skills with tier membership |
| `doctor.sh` | Health check for a deployed project |
