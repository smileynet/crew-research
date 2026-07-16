---
type: decision
title: "ADR 0008: Unify Tiers and Plugins into Single Deployment Model"
---

# ADR 0008: Unify Tiers and Plugins into Single Deployment Model

**Status:** Accepted (shipped 2026-07-14 — extensions model deployed, plugins/ removed)
**Date:** 2026-07-10
**Deciders:** smileynet

## Context

Tiers and plugins are two independent deployment systems that share the same target directories but don't know about each other. This causes:

1. **Tier deploy prunes plugin files** — required reconciliation logic to preserve plugin-installed steering/skills during tier re-deploy (bug fixed in `caf05f3`, introduced new complexity)
2. **AGENTS.md rendering must merge both** — the codex/agy deploy overwrites AGENTS.md each time, requiring explicit plugin-content injection into the render loop
3. **Two state systems** — tier is implicit (whatever's deployed), plugins tracked in `~/.crew-research/plugins.json`. Neither knows what the other deployed.
4. **`grep -qx` deduplication** — every merge point needs "is this already in the list?" checks that interact poorly with `set -e` (the bug we just hit)
5. **Separate install commands** — users must run `--tier X` then separately `--plugin Y`, and re-running tier can break the plugin

The ONLY functional difference between a tier skill and a plugin skill is: **plugins have an external prerequisite** (a CLI tool on PATH). Everything else — deployment targets, file format, prune behavior — should be identical.

## Decision

Merge plugins into tiers as **extensions** — optional skill/steering bundles gated on prerequisite availability.

### New tier manifest format

```yaml
description: "Minimal global — session continuity, planning, building, shipping fundamentals."

steering:
  - ai-generation-hygiene
  - verification-protocol
  - project-conventions
  - source-authority
  - context-budget-awareness
  - image-handling
  - subagent-reliability

skills:
  - handoff
  - read-handoff
  - cheatsheet
  - planning-cycles
  - ...

extensions:
  - name: recall
    description: "Cross-session memory"
    prerequisite:
      command: "recall --version"
      install_hint: "uv tool install recall"
    steering: [recall-session-start, recall-check]
    skills: [recall]
```

### Behavior

1. **Single deploy command:** `mise run init -- --global --tier basic --tool kiro-cli`
2. **Extensions auto-detect:** During deploy, each extension's `prerequisite.command` is tested. If it passes, the extension's steering + skills deploy alongside the tier's. If it fails, a note is printed: `⚠️ recall extension skipped (recall not on PATH). Install: uv tool install recall`
3. **Explicit opt-out:** `--skip-extension recall` prevents deployment even if prerequisite passes
4. **Explicit opt-in:** `--extension recall` forces deployment attempt (fails hard if prerequisite missing)
5. **One prune loop:** The DESIRED set includes tier + all passing extensions. No reconciliation needed.
6. **No separate state file:** `plugins.json` eliminated. The tier manifest IS the source of truth. What's deployed is determined by `tier manifest + prerequisite availability` at deploy time.

### Migration

- `--plugin recall` becomes: ensure `recall` CLI is installed, then re-run tier deploy (auto-detects)
- `--remove-plugin recall` becomes: `--skip-extension recall` on next deploy, or just uninstall the `recall` CLI
- `plugins.json` is read during migration (for backwards compat) then deleted after first successful unified deploy

## Consequences

**Positive:**
- Single deployment model, single prune loop, single state
- Bug class "tier deploy prunes plugins" eliminated by design
- AGENTS.md rendering is one pass (tier + extensions together)
- Users run one command, extensions appear automatically when prereqs are met
- Simpler generator code (remove ~50 lines of reconciliation logic)

**Negative:**
- Breaking change for users who use `--plugin` (need migration path)
- Extensions are tier-scoped (an extension in `basic` is also in `full`). If an extension should ONLY be in full, it goes in `full.yaml` only.
- Prerequisite auto-detection runs on every deploy (adds ~1s for `command -v` checks)

**Neutral:**
- `compositions/plugins/` directory can be eliminated (content moves into tier manifests)
- OR kept as referenced includes: `extensions: !include plugins/recall.yaml`

## Alternatives Considered

1. **Keep separate but fix reconciliation** — what we've been doing. Each fix adds complexity. The two systems keep interfering.
2. **Plugin state in tier manifest** — track which plugins are "enabled" in a state file that the tier deploy reads. Still two concepts, just better coordinated.
3. **This proposal** — eliminate the distinction entirely. Extensions are just conditional skill bundles.

Option 3 is simplest long-term.

## Implementation Plan

### Phase 1: Add extensions to tier manifests (non-breaking)

1. Add `extensions:` section to `basic.yaml` and `full.yaml`
2. Update `init.sh` to process extensions (test prerequisite → deploy if passes)
3. Extensions are included in DESIRED_FILES for prune
4. Remove the separate prune-preservation logic (superseded)
5. `--plugin` still works (reads from plugins/ dir, same as today) — deprecated with warning

### Phase 2: Migrate users (breaking)

1. `--plugin recall` prints: "Deprecated. Extensions auto-deploy when prerequisite is met. Run tier deploy to activate."
2. First tier deploy reads `plugins.json`, notes which extensions to force-enable, then deletes the file
3. Remove `plugins.json` state tracking
4. Remove `--plugin` / `--remove-plugin` code paths

### Phase 3: Cleanup

1. Move `compositions/plugins/*.yaml` content into tier manifests (or use YAML includes)
2. Remove `compositions/plugins/` directory
3. Update docs, README, cheatsheet

### Effort estimate

| Phase | Effort | Risk |
|-------|--------|------|
| 1 | 45 min | Low — additive, backward-compatible |
| 2 | 30 min | Medium — breaking change for `--plugin` users |
| 3 | 15 min | Low — cleanup |
