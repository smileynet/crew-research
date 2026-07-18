---
name: deploy-toolkit
description: "Run and interpret crew-research deploy tooling — init.sh, doctor.sh, catalog.sh, prune semantics, manifests, ADR 0009 reference placement. Use when deploying tiers, diagnosing skill/steering deployment, reading doctor warnings, or verifying deploy idempotency. Trigger: deploy the tier, init.sh, doctor output, pruned, unmanaged skill, crew-skills manifest, steering references, redeploy."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Deploy Toolkit

```bash
bash tools/generator/init.sh --global --tier full --tool kiro-cli [--tool codex --tool agy]
bash tools/generator/init.sh --project <path>          # scaffold project workspace
bash tools/generator/init.sh --skip-extension recall   # opt out of an extension
bash tools/generator/doctor.sh                         # health check
bash tools/generator/catalog.sh                        # browse available skills
```

## Placement semantics (ADR 0009)

- Steering bodies → eager dir (`~/.kiro/steering/*.md`, or rendered into AGENTS.md for codex/agy).
- Steering companion `references/` → the tool's **skills tree** (`skills/{name}/references/`) — non-eager, read on demand; deployed bodies have links rewritten to absolute paths.
- `~/.kiro/steering/references/` is **user-owned files only** (e.g., environment-gotchas.md) — deploys never touch unknown files there.
- Skills scoped via `metadata.tool`/`metadata.tools` deploy only to matching tools (e.g., mcp-partitioning is kiro-only).

## Reading deploy output

| Line | Meaning |
|------|---------|
| `N updated, M pruned, K unchanged` | **Idempotency invariant: an immediate second run must be `0 updated, 0 pruned`.** Anything else = a flapping bug — investigate before shipping |
| `pruned: <file> (moved to skills tree — ADR 0009)` | one-time migration of old eager refs |
| `pruned: skills/X/ (left the tier)` | X was in the manifest but no longer in the tier |
| `pruned: skills/X/ (deprecated — replaced by: Y)` | X is in `compositions/deprecated.yaml` |
| `kept (symlink): ...` | symlinks are never pruned — the personal-customization escape hatch |
| `⚠️ unmanaged (kept): skills/X/` | dir we didn't deploy (another project's or hand-made) — warned, never deleted |

## Manifests (what prune trusts)

- `~/.kiro/.crew-skills` — skill dirs the last kiro deploy owned (includes steering-reference dirs). Prune only removes names found here or in deprecated.yaml. **Never hand-edit.**
- `<skills_dest>/.crew-skills-{codex|agy}` — per-tool manifests; codex and agy SHARE `~/.agents/skills/` with different tool-scoped sets, so each prunes only what it deployed (prevents cross-tool delete flapping).
- `~/.kiro/.crew-tier` — deployed tier name; doctor reconciles against it.

## Doctor output

`✅ Healthy` needs all checks green. Warnings are advisory: unmanaged skill dirs (symlink them to make ownership explicit), deprecated dirs (next deploy prunes), stale steering drift. Doctor never modifies anything.

## Retiring a skill

Delete from `atomics/skills/` + add entry to `compositions/deprecated.yaml` (name, replaced_by, reason, since) in the SAME commit — deploys then prune it everywhere; lint blocks name reuse.
