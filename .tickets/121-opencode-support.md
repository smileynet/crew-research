---
id: "121"
title: "Add opencode as a first-class deployment target"
status: open
blocked_by: []
priority: high
---

# Add opencode as a first-class deployment target

## Intent

OpenCode (anomalyco/opencode, v1.14.19+) is now deployed and working on this machine. It already auto-loads skills from `~/.agents/skills/` and `~/.claude/skills/` — meaning our existing codex/crush deployment partially works. But opencode has its own native paths (`~/.config/opencode/skills/`, `~/.config/opencode/agents/`) and config format (`opencode.json` with `instructions` array instead of a single AGENTS.md). It deserves first-class support via `--tool opencode`.

## Context

- OpenCode skill/steering paths (from `opencode debug skill` built-in docs):
  - Global skills: `~/.config/opencode/skills/<name>/SKILL.md`
  - Global agents: `~/.config/opencode/agents/<name>.md`
  - Global config: `~/.config/opencode/opencode.json`
  - External (auto-loaded): `~/.agents/skills/`, `~/.claude/skills/`
  - Instructions: `opencode.json` → `"instructions": ["AGENTS.md", ...]`
- OpenCode uses SKILL.md format identical to ours (frontmatter: name, description)
- `deploy_agents_md_tool()` in init.sh is the generic pattern for non-kiro tools
- CloseCode adapter proof exists at `tools/proofs/adapters/closecode.yaml`
- Audit: `.scratch/opencode-audit.md`

## What to build

1. **init.sh**: Add `deploy_opencode()` function using `deploy_agents_md_tool` with:
   - `skills_dest`: `~/.config/opencode/skills` (native path, not the fallback `~/.agents/`)
   - `agents_md_dest`: write steering as AGENTS.md, then add to `opencode.json` `instructions` array
2. **init.sh**: Add `opencode)` case in the tool loop (~line 355)
3. **doctor.sh**: Add opencode validation block (check `opencode --version`, skill count at native path, instructions config)
4. **README.md**: Add opencode row to Multi-Tool Deployment table
5. **AGENTS.md**: Add opencode to Deployment section
6. **user-setup-guide.md**: Add opencode examples
7. **Adapter proof**: `tools/proofs/adapters/opencode.yaml`

## Design considerations

- OpenCode auto-loads from `~/.agents/skills/` already — do we deploy to native path AND get auto-load for free, or choose one? Recommend: native path only (`~/.config/opencode/skills/`) for clean ownership.
- `opencode.json` `instructions` array vs standalone AGENTS.md: opencode reads files listed in `instructions`, so we can either append our AGENTS.md path or write steering inline. Recommend: write `~/.config/opencode/AGENTS.md` and ensure `instructions` includes it.
- Prune semantics: opencode config is JSON (not a directory of files) — prune needs to handle `opencode.json` mutations carefully.

## Acceptance criteria

- [ ] `mise run init -- --global --tier basic --tool opencode` succeeds
- [ ] Skills deployed to `~/.config/opencode/skills/` with correct SKILL.md format
- [ ] Steering concatenated and referenced in opencode.json instructions
- [ ] `mise run doctor -- --tool opencode` reports healthy
- [ ] `opencode debug skill` lists deployed skills
- [ ] Idempotent: running init twice produces same result
- [ ] Does not break existing `~/.agents/skills/` deployment for codex/crush
