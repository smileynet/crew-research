---
id: "98"
title: "Skill import protocol — external repos own and deploy their skills with version checking"
status: open
blocked_by: []
env: either
priority: high
---

# Skill Import Protocol

## Problem

Skills for external tools (tkt, recall, archwright) currently live in two places:
- **archwright**: owns its skills in its repo, self-deploys via symlinks (known-tools pattern)
- **tkt**: has NO skills in its repo; crew-research owns the ticket-related skills
- **recall**: has NO skills in its repo; crew-research owns the recall skill

This creates unclear boundaries. When recall or tkt adds a feature, crew-research must
update ITS skill to document it. The tool repo can't ship or version its own guidance.
archwright solved this with self-deploy — tkt and recall should follow the same pattern.

## What to build

A formalized protocol for external repos to own, deploy, and version their skills, with
crew-research providing detection, health checking, and catalog integration.

### 1. Skill ownership moves to the tool repo

Each tool repo gets a `skills/` directory:
```
recall/
  skills/
    recall/SKILL.md          # the recall skill (currently in crew-research)
    recall/references/...
  SKILL_MANIFEST.yaml        # version, deploy paths, compatibility

tkt/
  skills/
    ticket-planning/SKILL.md  # could own this
    tkt/SKILL.md              # tkt CLI usage skill
  SKILL_MANIFEST.yaml
```

### 2. SKILL_MANIFEST.yaml (new contract)

Each tool repo declares what it ships:
```yaml
name: recall
version: "0.2.0"                    # tool version this manifest matches
min_crew_version: "0.9.0"           # minimum crew-research deployment version
skills:
  - name: recall
    path: skills/recall
    replaces: "atomics/skills/recall"  # what it supersedes in crew-research
deploy:
  method: symlink                    # symlink | copy
  target: "~/.kiro/skills/"          # where skills land
  script: "tools/deploy-skills.sh"   # optional deploy script
binary:
  name: recall
  version_cmd: "recall --version"
  min_version: "0.2.0"              # minimum binary version for these skills
```

### 3. Detection and health checking (doctor.sh enhancements)

`doctor.sh` currently checks for broken symlinks. Extend to:

1. **Binary version check**: run `version_cmd`, compare against `min_version`
2. **Skill freshness check**: compare deployed skill content hash against source repo
   skill content hash (detect stale symlinks pointing at old checkouts)
3. **Compatibility check**: verify `min_crew_version` against deployed crew-research version
4. **Missing skill detection**: if binary is on PATH but skills aren't deployed, suggest hydration

Output:
```
Known tools:
  ✅ archwright (v1.2.0) — 14 skills, all current
  ⚠️  recall (v0.1.0 → v0.2.0 available) — skill stale (deployed from v0.1.0 checkout)
  ❌ tkt (v0.1.0) — binary present, skills not deployed (run: bash ~/code/tkt/tools/deploy-skills.sh)
```

### 4. catalog.sh integration

`mise run catalog` already lists known tools. Enhance to show:
- Which skills come from external repos vs crew-research
- Version of the deployed skill vs current tool version
- Whether the skill is the crew-research fallback or the tool-owned version

### 5. Migration path

For recall and tkt, the transition:
1. Copy the skill FROM crew-research INTO the tool repo's `skills/` dir
2. Add `SKILL_MANIFEST.yaml` to the tool repo
3. Add a `tools/deploy-skills.sh` to the tool repo (same pattern as archwright)
4. Update `known-tools.yaml` to register the new tool
5. In crew-research: keep the skill as a **fallback** (used when tool is installed but
   hasn't deployed its own skills yet), with a note pointing to the tool-owned version
6. On next crew deploy: if tool-owned symlink exists, crew-research's copy is skipped

### 6. Fallback strategy

When a tool binary is on PATH but its skills haven't been deployed:
- crew-research's built-in copy activates (backward compat)
- doctor warns: "recall skill is crew-research's fallback; for latest, deploy from recall repo"
- The fallback is NEVER deleted — it ensures the tool works with just `uv tool install`

## Acceptance criteria

- [ ] `SKILL_MANIFEST.yaml` schema defined and documented
- [ ] At least one tool (recall or tkt) migrated: skills live in tool repo, deploy via symlink
- [ ] `doctor.sh` checks: binary version, skill freshness, compatibility, missing skills
- [ ] `catalog.sh` shows provenance (crew-research fallback vs tool-owned)
- [ ] Fallback path works: tool installed without deploy-skills → crew skill activates
- [ ] Stale detection works: tool repo updated but skill symlink points at old checkout
- [ ] `known-tools.yaml` updated with recall and tkt entries

## Design decisions to make

1. **Who triggers deploy-skills.sh?** Options:
   - Manual (user runs after install/update) — current archwright pattern
   - Automatic (crew-research init detects binary + repo and runs deploy) — more magical
   - Prompted (doctor suggests, user confirms) — middle ground

2. **Version source of truth**: Does the manifest version match the Cargo.toml/pyproject.toml
   version, or is it independent? (Recommendation: same version, validated by CI.)

3. **Skill override priority**: When both crew-research fallback and tool-owned skill exist:
   - Symlink wins (it's more specific — the deploy put it there intentionally)
   - Identical slug: tool-owned replaces crew-owned (no duplication in the skills tree)

4. **Cross-repo CI**: Should the tool repo's CI validate its skills against
   crew-research's skill schema? (Yes — `mise run validate` from crew-research should
   be runnable against a manifest.)

## Out of scope

- Skill marketplace / registry beyond known-tools.yaml
- Auto-updating tool binaries (that's ticket 35 in recall)
- Hosting skills outside of git repos

## References

- Current known-tools pattern: `compositions/known-tools.yaml`
- archwright deploy script: `~/code/archwright/tools/deploy-skills.sh`
- doctor.sh known-tool detection: `tools/generator/doctor.sh` L98-120
- User setup guide symlink convention: `.kiro/steering/user-setup-guide.md`
- Recall repo: `~/code/recall` (cloned 2026-08-06)
- tkt repo: github.com/smileynet/tkt
