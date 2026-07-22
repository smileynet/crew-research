---
id: "22"
title: "mcp-partitioning skill — agent/MCP breakout guidance"
status: done
blocked_by: []
spec: ""
---

# mcp-partitioning skill

## What was built

`atomics/skills/mcp-partitioning/` — reference skill distilled from a measured
migration (dotfiles/sa-system-setup, 2026-07-18: 9 global MCP servers / ~230 tools
→ 2 servers / ~14 tools per default session):

- Placement rule: lean default agent (2–3 essential servers), specialists in named agents
- The zero-tools trap: kiro-cli agents need a `tools` whitelist + opt-in inheritance
  (`useLegacyMcpJson: true`), and the whitelist gates inherited servers too —
  configs that look right load nothing (`references/kiro-cli.md` has the verified shape)
- Validation pattern: sentinel-word probes — positive per agent, NEGATIVE on the
  default agent (proves the partition), anti-vacuous drill (deliberate violation)
- Config file classes: symlink-managed vs content-managed (tools that atomically
  rewrite their config destroy symlinks — check content instead)
- Team deploy semantics: copy-if-missing, force+backup to replace

## Follow-ups (open when picked up)

- Add to `compositions/tiers/full.yaml` skills list (Build or Maintain section) — done in this change
- Run through lint (`tools/lint/check-crosslinks.sh`) — done in this change
- Eval definition for activation (does "my sessions feel slow / too many tools"
  trigger it?) — future eval-suite pass

## Evidence

- Source migration: dotfiles tickets 001–007 + sa-system-setup `kiro-agents/` +
  `sa doctor` agent checks; strategy/evidence: dotfiles `.memory/mcp-partitioning-strategy.md`

## Resolution
**Closed:** 2026-07-18 (Resolution backfilled 2026-07-22). mcp-partitioning reference skill landed in `atomics/skills/` and the full tier, distilled from the measured dotfiles/sa-system-setup migration (9 servers/~230 tools → 2 servers/~14 tools per default session); tier addition and lint pass done in the same change, activation eval left as a future follow-up. Evidence: docs/plan.md row 22 ("✅ done (2026-07-18, 34582a0)"); closing commit 34582a0 (ticket created already done — retrospective write-up).
