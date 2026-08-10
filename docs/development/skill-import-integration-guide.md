# Skill Import Protocol — Integration Guide

How to make your tool repo own and deploy its skills, with version checking and
auto-deploy integration with crew-research.

## Overview

The skill import protocol lets external tool repos (recall, tkt, archwright, etc.)
own their skills while crew-research handles detection, health checking, and catalog
integration. You package skills using the [Agent Plugins](https://agent-plugins.org/)
directory convention and add a lifecycle manifest for crew-research compatibility.

## Prerequisites

- A tool repo with something worth teaching an AI assistant (CLI commands, workflows, patterns)
- `yq` on PATH (for manifest validation)
- Familiarity with the [Agent Skills format](https://agentskills.io/specification)

## Quick Start (5 minutes)

```bash
# From your tool repo root:
bash ~/code/crew-research/tools/plugin/init-plugin.sh .

# Follow the prompts, then:
# 1. Edit skills/*/SKILL.md with real content
# 2. Validate:
bash ~/code/crew-research/tools/plugin/validate-plugin.sh .
# 3. Deploy:
bash tools/deploy-skills.sh
```

## What Gets Generated

```
your-tool/
  plugin.json              # Agent Plugins 1.0 manifest (ecosystem discovery)
  SKILL_MANIFEST.yaml      # crew-research lifecycle contract (version/deploy/compat)
  skills/
    your-tool/
      SKILL.md             # Agent Skills format (name + description frontmatter + markdown)
      references/          # Progressive-loading companion docs
  tools/
    deploy-skills.sh       # Multi-tool deploy (kiro, claude, codex)
```

## File-by-File Reference

### plugin.json (Agent Plugins 1.0)

Makes your skills discoverable by any Agent Plugins-conformant client (Cursor, Claude Code,
VS Code, etc.). Minimal required fields:

```json
{
  "$schema": "https://agent-plugins.org/schemas/1.0.0/plugin.schema.json",
  "name": "your-tool",
  "version": "1.0.0",
  "description": "What your tool does",
  "license": "MIT",
  "keywords": ["relevant", "tags"]
}
```

**Rules:**
- Name: 1-64 chars, lowercase `[a-z0-9.-]`, no `--` or `..`, start/end alphanumeric
- Schema is CLOSED — no extra top-level fields (use `extensions` for custom data)
- Version: SemVer recommended, should match your Cargo.toml / pyproject.toml

### SKILL_MANIFEST.yaml (crew-research lifecycle)

Declares version compatibility, binary requirements, and deploy configuration.
Full schema: `tools/plugin/schemas/skill-manifest.schema.yaml`

```yaml
name: your-tool
version: "1.0.0"
description: "What your tool does"

compatibility:
  crew_research: "~> 0.9"    # works with 0.9+, may break at 1.0

binary:
  name: your-tool             # binary name on PATH
  version_cmd: "your-tool --version"
  min_version: "1.0.0"       # minimum binary for these skills

# Set binary: null if your tool has no CLI binary (e.g. archwright)

skills:
  - name: your-tool
    path: skills/your-tool
    replaces: "atomics/skills/your-tool"   # optional: crew-research fallback it supersedes

deploy:
  method: symlink             # symlink (preferred) or copy (Windows fallback)
  auto: true                  # crew-research init.sh auto-deploys when detected
  script: tools/deploy-skills.sh
```

### skills/your-tool/SKILL.md

Standard Agent Skills format:

```markdown
---
name: your-tool
description: "Trigger keywords here — what activates this skill"
metadata:
  type: reference
  invocation: both
  practice: null
---

# Your Tool

## What it does

...

## Commands

...
```

**Rules:**
- `name` and `description` are required frontmatter fields
- `description` doubles as activation trigger — use distinctive keywords
- Keep under 100 lines; put details in `references/`
- `references/` loads progressively (only when the agent needs deeper context)

### tools/deploy-skills.sh

Multi-tool deploy script. The generated template supports `--tool kiro|claude|codex` and
`--project <path>`. Global kiro deploys use symlinks (survive crew-research prune);
project and non-kiro deploys use copies.

## How crew-research Detects Your Tool

After registration in `compositions/known-tools.yaml`:

1. **doctor.sh** checks:
   - Binary on PATH? (`which your-tool`)
   - Skills deployed? (glob match in skills tree)
   - Symlinks healthy? (no broken links)
   - Version fresh? (binary version vs manifest min_version)
   - Content fresh? (deployed hash vs source hash)

2. **init.sh** auto-deploys:
   - Binary on PATH ✓
   - Repo found at manifest path (or `~/code/{name}` convention) ✓
   - `SKILL_MANIFEST.yaml` passes validation ✓
   - `deploy.auto: true` in manifest ✓
   - Not in `CREW_SKIP_TOOL_DEPLOY` env var ✓

3. **catalog.sh** shows provenance:
   ```
   recall (v0.2.0, symlink from ~/code/recall)
   tkt (v0.1.0, crew-research fallback — deploy from tool repo for latest)
   ```

## Fallback Strategy

When a tool binary is on PATH but skills haven't been deployed from the tool repo:
- crew-research's built-in copy activates (backward compat)
- doctor warns: "using crew-research fallback; for latest, run deploy-skills.sh"
- The fallback is NEVER deleted — it ensures the tool works with just `cargo install`

Priority: tool-repo symlink > crew-research fallback copy

## CI Integration

Add to your tool repo's CI:

```yaml
# .github/workflows/validate-skills.yml
- name: Validate skill compliance
  run: |
    git clone --depth 1 https://github.com/smileynet/crew-research /tmp/crew-research
    bash /tmp/crew-research/tools/plugin/validate-plugin.sh .
```

This validates:
- Manifest schema compliance
- plugin.json format (if present)
- Skill directory naming rules
- SKILL.md frontmatter requirements
- Path containment (no escaping plugin root)

## Version Lifecycle

1. **You update your tool** (new feature, breaking change)
2. **Update skill content** to document the change
3. **Bump version** in Cargo.toml/pyproject.toml + SKILL_MANIFEST.yaml + plugin.json
4. **Push** — users with symlinks get the update immediately (git pull)
5. **Users with copies** — doctor.sh detects staleness, suggests re-deploy

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `validate-plugin.sh` fails on naming | Skill dirs must be lowercase `[a-z0-9-]` only |
| Skills not activating after deploy | Check `~/.kiro/skills/your-tool/SKILL.md` exists |
| doctor shows "stale" after git pull | Symlinks auto-update; copies need re-deploy |
| init.sh doesn't auto-deploy | Check: binary on PATH, repo at expected path, `auto: true` |
| Conflict with crew-research fallback | Symlink takes priority; delete fallback copy if both exist |
| Windows: symlinks fail | deploy-skills.sh falls back to copy on Windows/non-kiro |

## Reference Implementations

- **archwright** (`~/code/archwright`): 16 skills, full deploy-skills.sh with steering,
  domain overlays, multi-tool support. The most complete example.
- **Agent Plugins example** (`.references/agent-plugins-example/`): Minimal reference
  for the Agent Plugins 1.0 format.
- **Agent Plugins spec** (`.references/agent-plugins-spec/`): Full normative spec +
  JSON Schema files.

## Links

- Agent Plugins spec: https://agent-plugins.org/
- Agent Plugins GitHub: https://github.com/agentplugins/agent-plugins-spec
- Agent Skills format: https://agentskills.io/specification
- crew-research ticket 98: `.tickets/98-skill-import-protocol.md`
- Schema: `tools/plugin/schemas/skill-manifest.schema.yaml`
