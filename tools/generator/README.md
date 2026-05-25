# Generator

Composes atomic modules and compositions into tool-specific deployments.

## Commands

```bash
# Validate all compositions (check references, schema)
./generate.sh validate

# Generate deployment for a specific tool
./generate.sh generate --tool kiro-cli --output ./deploy

# Initialize a new project with workspace conventions
./init.sh --project ~/code/myproject --crews general,content --tool kiro-cli
```

## Scripts

| Script | Purpose |
|--------|---------|
| `generate.sh` | Validate compositions and generate tool-specific output |
| `init.sh` | Bootstrap a project with crew-research conventions |
