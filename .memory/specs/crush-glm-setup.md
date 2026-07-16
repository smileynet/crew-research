---
type: spec
title: Crush + GLM Setup
---

# Crush + GLM Setup

Crush (by Charmbracelet) is a terminal-first AI coding agent, deployed alongside kiro-cli, codex, and agy as a fourth tool target for crew-research skills.

## Configuration

Config location: `~/.config/crush/crush.json`

```json
{
  "providers": {
    "zai": {
      "id": "zai",
      "name": "ZAI Provider",
      "type": "openai-compat",
      "base_url": "https://api.z.ai/api/coding/paas/v4",
      "api_key": "$ZAI_API_KEY"
    }
  },
  "models": {
    "large": {
      "model": "glm-5.2",
      "provider": "zai"
    },
    "small": {
      "model": "glm-5.2",
      "provider": "zai"
    }
  }
}
```

Key points:
- Uses the **Coding Plan endpoint** (`/api/coding/paas/v4`), not the pay-as-you-go API
- Coding Plan supports only 3 models: GLM-5.2, GLM-5-Turbo, and GLM-4.7
- No custom model registration needed — GLM-5.2 is in Crush's built-in Z.AI catalog
- Uses Crush's current `models.large` and `models.small` selection schema
- Both roles use GLM-5.2 — on Max plan with 1x off-peak promo, no need for a separate small model
- Quota: GLM-5.2 burns 3x during peak hours, 1x off-peak (1x promo through Sept 2026)

Verify the configuration before running an eval:

```bash
crush models | grep '^zai/glm-5.2$'
crush run --quiet --model zai/glm-5.2 "Reply with exactly OK"
```

## Coding Plan Constraints

The Z.AI Coding Plan (Max: $72/month) provides flat-rate access but with restrictions:
- **Supported models:** GLM-5.2, GLM-5-Turbo, GLM-4.7 only
- **Endpoint:** Must use `https://api.z.ai/api/coding/paas/v4` (OpenAI-compat protocol)
- **Supported tools:** Crush is officially listed as a supported tool
- **Quota:** ~1600 prompts/5h on Max plan; GLM-5.2 burns at 3x peak / 1x off-peak (1x promo through Sept)
- **GLM-4.7-FlashX is NOT available** on Coding Plan — requires pay-as-you-go balance at `/api/paas/v4`

If Crush resolves the model but Z.AI returns `Insufficient balance or no resource package`, the model is not included in the Coding Plan. Only GLM-5.2, GLM-5-Turbo, and GLM-4.7 are supported.

## Tool Characteristics

| Property | Value |
|----------|-------|
| Install | `npm install -g @charmland/crush` |
| Version | 0.84.1+ |
| Non-interactive | `crush run -m <model> "<prompt>"` |
| Model selection | `-m zai/glm-5.2` or `--small-model` |
| Subagent support | **None** — single-agent tool |
| Skill source | `.kiro/` (shared with kiro-cli deploy path) |
| Deploy command | `mise run init -- --global --tier full --tool crush` |

## Deployment

Crush shares the kiro-cli deploy path — skills go to `~/.kiro/skills/` and steering to `~/.kiro/steering/`. The `init.sh` script maps `--tool crush` to the same `deploy_kiro_cli()` function.

## Model Selection Rationale

### Main model: GLM-5.2
- Z.ai's flagship (June 2026), 753B MoE, 1M context
- Near-frontier coding (DeepSWE 46.2, up from 18 on GLM-5.1)
- MIT licensed, no regional restrictions
- $1.40/$4.40 — roughly 1/6 the cost of GPT-5.5

### Small model: GLM-5.2 (same as main)
- On Max Coding Plan, GLM-5.2 is effectively free at margin
- Opus-class quality means no compromise on small tasks
- Quota burn (3x peak) is acceptable on Max tier (~530 prompts/5h at all-5.2)
- Eliminates config complexity of maintaining a separate small model
- Off-peak promo (1x through Sept 2026) makes this a non-issue during nights/weekends

## Available Z.AI Text Models (July 2026)

| Model | Input $/1M | Output $/1M | Notes |
|-------|-----------|------------|-------|
| GLM-5.2 | $1.40 | $4.40 | Flagship, 1M context |
| GLM-5.1 | $1.40 | $4.40 | Previous flagship |
| GLM-5 | $1.00 | $3.20 | Base GLM-5 |
| GLM-5-Turbo | $1.20 | $4.00 | Agent/tool-calling optimized, 200K |
| GLM-4.7 | $0.60 | $2.20 | Strong coding |
| GLM-4.7-FlashX | $0.07 | $0.40 | Fast, cheap ← **small_model** |
| GLM-4.5-Air | $0.20 | $1.10 | Lightweight |
| GLM-4.7-Flash | Free | Free | Zero cost, basic |
| GLM-4.5-Flash | Free | Free | Zero cost, basic |

## Eval Integration

The eval harness supports crush as an adapter:
```bash
mise run eval:one -- --adapter crush --definition <name>
mise run eval:one -- --adapter crush --model zai/glm-4.7-flashx --definition <name>
```

## Limitations

- No subagent dispatch (confirmed by proof S1)
- Single-agent only — use for direct tasks
- Image analysis via stdin: `crush run "Describe" < image.png`
- Skills shared with kiro-cli — changes to one affect both
