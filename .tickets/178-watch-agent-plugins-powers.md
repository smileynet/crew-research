---
id: "178"
title: "WATCH — optional export-skills-as-plugin target if a 2nd tool adopts the Agent Plugins spec"
status: backlog
blocked_by: []
tags: [kiro-v3]
---

# WATCH: Agent Plugins / Powers

kiro-cli **2.25.0** added Powers install/uninstall (`/powers …` or `kiro-cli powers …`).
Powers package capabilities (MCP-centric) via the open, multi-vendor **Agent Plugins**
spec ("build once, works across compatible clients" — Amazon/Cursor/Microsoft/OpenAI/Vercel).

**Why watch, not adopt:** do NOT restructure skills into the Power layout — it couples a
tool-agnostic repo to a kiro-v3-only, MCP-centric packaging format and breaks the
codex/crush/agy portability that is crew-research's reason to exist. The headline Power
benefit (dynamic MCP tool loading) is irrelevant to a repo that ships no MCP servers.
The thing worth watching is the **Agent Plugins spec itself**.

**Activate when:** a SECOND crew-research-supported tool (codex / crush / agy / opencode)
ships Agent Plugins support. Then prototype an OPTIONAL, additive deploy target that
*exports* existing SKILL.md files as a plugin (`plugin.json` with keywords from each
skill's description) — never default, never a prerequisite.

## Acceptance criteria (when activated)

- [ ] Confirm ≥2 supported tools implement Agent Plugins
- [ ] Prototype additive export-skills-as-plugin target (opt-in); SKILL.md stays source of truth
- [ ] knowledgeBase re-check: still weaker read-guarantee than skill://? (ignore unless it changed)
