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

### Informed by research (2026-08-09)

**1. Manifest schema — use the VS Code `engines` pattern (floor-only, semver range)**

The ecosystem consensus (VS Code, npm, Terraform, WordPress) is: declare a minimum
compatible version (floor), not a ceiling. WordPress's `Tested up to` (soft ceiling) is
informational only. Terraform's `~>` (pessimistic constraint) is the cleanest for our case:

```yaml
compatibility:
  crew_research: "~> 0.9"   # >=0.9.0, <1.0.0
```

This means: "these skills work with crew-research 0.9+, may break at 1.0." Simple, proven.

**2. Deploy method — symlink (current archwright pattern), with copy fallback for Windows**

Research validates symlinks as the dominant deployment pattern (Stow, Nix, Homebrew, npx
skills). Key finding: the `symlink-or-copy` npm package exists precisely because Windows
without Developer Mode can't create symlinks. Our pattern:
- Default: symlink (reversible, single source of truth, `stow -D` equivalent)
- Windows fallback: copy with content-hash tracking (detect drift)
- Health: `find -L path -type l` for broken symlinks (already in doctor.sh)

**3. Ownership model — "blessed third-party" (Terraform partner tier)**

Research shows three tiers everywhere. Our model maps cleanly:
- **Core-owned** (Tier 1): skills in `atomics/skills/` — crew-research maintains
- **Blessed** (Tier 2): recall, tkt, archwright — own their skills, crew validates compat
- **Community** (Tier 3): future — anyone's skill repo via `npx skills` or manual install

The key contract: crew-research guarantees the SKILL.md format spec (Agent Skills) and the
deployment paths. Tool repos guarantee their skills work with the declared crew version.

**4. Testing across boundaries — conformance via `mise run validate`**

The Terraform pattern: core provides test framework, plugin owners run it. Our equivalent:
- crew-research provides `tools/generator/generate.sh validate` (schema check)
- Tool repos run it in their CI against their `skills/` directory
- crew-research CI does NOT run tool repo tests — too coupled
- Version compat verified by: tool repo CI pins crew-research ref, runs validate

**5. Fallback strategy — graceful degradation (Backstage model)**

Research shows fallback correlates with coupling:
- Tight coupling (ESLint rules) → hard fail
- Loose coupling (Backstage UI tabs) → degrade gracefully

Our skills are loosely coupled — absence means the skill doesn't activate, not that the
system breaks. So: fallback copy in crew-research, tool-owned symlink takes priority,
absence = warning not error.

**6. Migration pattern — Ansible 2.10 extraction with routing**

The proven extraction pattern:
1. Define the manifest contract first (SKILL_MANIFEST.yaml)
2. Copy skill to tool repo, add manifest + deploy script
3. crew-research skill becomes a "tombstone" — still works but warns "latest is in the tool repo"
4. After N deploys with the tool-owned version active, consider removing the crew copy

**7. Version detection — binary `--version` + manifest comparison**

doctor.sh checks:
- Binary present? → `which recall`
- Binary version? → `recall --version` (parse against manifest `min_version`)
- Skills deployed? → check symlink existence in skills tree
- Skills fresh? → compare deployed skill hash vs source repo hash
- Compatible? → compare crew-research version against manifest `compatibility`

**8. Discovery of tool repos — convention over configuration**

Research finding: `npx skills` detects installed agents by known path conventions. We can do
the same for tool repos:
- Check `~/code/{tool-name}` (convention from AGENTS.md)
- Check manifest's declared `repo` path
- Fall back to asking if not found

### Decisions that still need human input

- Should `init.sh` auto-run deploy-skills.sh when it detects a tool repo? (Or just suggest?)
- Should `mise run validate` be runnable against a remote manifest URL (for CI)?
- Should we adopt the Agent Plugins 1.0 `plugin.json` format instead of our own manifest?
  (It's new as of Aug 2026, backed by Amazon/Microsoft/OpenAI/Vercel/Cursor, but
  deliberately excludes installation — just the directory shape)

## References

- Current known-tools pattern: `compositions/known-tools.yaml`
- archwright deploy script: `~/code/archwright/tools/deploy-skills.sh`
- doctor.sh known-tool detection: `tools/generator/doctor.sh` L98-120
- User setup guide symlink convention: `.kiro/steering/user-setup-guide.md`
- Recall repo: `~/code/recall` (cloned 2026-08-06)
- tkt repo: github.com/smileynet/tkt
- Research: `.scratch/research/plugin-registries.md`
- Research: `.scratch/research/symlink-deploy-patterns.md`
- Research: `.scratch/research/version-compat-protocols.md`
- Research: `.scratch/research/skill-ownership-boundaries.md`
