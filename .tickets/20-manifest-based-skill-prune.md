---
id: "20"
title: "init.sh prunes only skills it deployed (manifest-based)"
status: done
blocked_by: []
spec: "t09-baseline-followups"
---

# init.sh prunes only skills it deployed

## What to build

Global deploy prune removes only skill directories crew-research itself deployed, tracked in a manifest (`~/.kiro/.crew-skills`). Unmanaged skill dirs get a warning, never deletion. doctor.sh surfaces the same warning.

## Context

- **Incident (2026-07-18):** `mise run init -- --global --tier full` pruned 14 unmanaged items from `~/.kiro/skills/`, including all 13 archwright-* skills deployed there by the archwright project's `deploy-skills.sh`. Restored via archwright's own deploy task.
- **Existing escape:** symlinked skill dirs are kept — but archwright deploys copies, and nothing warns copy-deployers of the risk.
- **Current logic:** `tools/generator/init.sh` prune loop deletes any `$DEST/skills/*/` not in the current tier's SKILLS array.
- **Design:** on deploy, write deployed skill names to `$DEST/.crew-skills`. Prune candidates = dirs absent from current tier AND present in the previous manifest (we deployed it, tier dropped it). Dirs absent from both = unmanaged → warn. First run without a manifest: warn-only (no legacy prune), manifest starts fresh.

## Acceptance criteria

- [ ] Deploy writes `~/.kiro/.crew-skills` manifest
- [ ] Skill dir in manifest but not in tier → pruned (tier removal works)
- [ ] Skill dir in neither manifest nor tier → warned, kept
- [ ] Symlink behavior unchanged (kept, noted)
- [ ] doctor.sh warns about unmanaged skill dirs
- [ ] Negative test: simulated foreign skill dir survives a full deploy
