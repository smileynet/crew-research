# Antigravity CLI (agy) — Research Findings

**Date:** 2026-06-14  
**Tool version:** agy 1.0.8  
**Status:** Adapter and proofs created. Auth blocker prevents automated execution.

## Discovery Mechanics (Verified from Docs)

### Skills
- **Global:** `~/.gemini/antigravity-cli/skills/{slug}/`
- **Workspace:** `.agents/skills/{slug}/`
- Same skill.md format (markdown with YAML frontmatter: name, description)
- Managed via `/skills` in-session. No CLI-level management command yet.
- Community skills: `npx skills install <name>`

### Context (Steering)
- **AGENTS.md:** Cross-tool foundation. `./AGENTS.md` + `~/.gemini/AGENTS.md`
- **GEMINI.md:** Agy-specific overrides. `./GEMINI.md` + `~/.gemini/GEMINI.md`
- **Precedence:** System rules > GEMINI.md > AGENTS.md > .agent/rules/
- **Nested:** Subdirectory AGENTS.md supported (opt-in via settings)

### Plugins
- Replaced Gemini CLI "extensions"
- Location: `~/.gemini/antigravity-cli/plugins/`
- Migration: `agy plugin import gemini`
- Commands become skills on import

### MCP
- Config: `.agents/mcp_config.json` (workspace), `~/.gemini/antigravity-cli/mcp_config.json` (global)
- Remote servers use `serverUrl` field (not `url`)

### Hooks
- JSON format (same as Antigravity 2.0)
- Lifecycle: before tool call, after file edit, session start

### Subagents
- Dynamic parallel background agents for async work
- Used for large refactors, multi-topic research

## CLI Interface (Verified)

| Flag | Purpose |
|------|---------|
| `--print` / `-p` | Non-interactive: run prompt, print response, exit |
| `--prompt-interactive` / `-i` | Run initial prompt then continue interactive |
| `--continue` / `-c` | Resume most recent conversation |
| `--conversation <id>` | Resume specific conversation |
| `--dangerously-skip-permissions` | Auto-approve tool calls |
| `--print-timeout` | Timeout for print mode (default 5m) |
| `--log-file <path>` | Debug log output |
| `--model <name>` | Override model |
| `--sandbox` | Run with terminal restrictions |
| `--add-dir <path>` | Add directory to workspace |

Subcommands: `changelog`, `help`, `install`, `models`, `plugin`

## Auth (Verified via Log)

- Auth: Google Sign-In via system keyring
- On first run: opens browser for OAuth
- SSH sessions: prints auth URL instead
- **Blocker:** Old Gemini IDE/CLI oauth creds (`~/.gemini/oauth_creds.json`) are NOT used by agy CLI.
  The agy binary has its own auth state. Requires interactive browser login.
- Error seen: `"You are not logged into Antigravity"` in log output

## Deployment (Implemented & Tested)

`mise run init -- --global --tool agy` deploys:
- 13 skills → `~/.gemini/antigravity-cli/skills/{slug}/SKILL.md`
- 5 steering sections → `~/.gemini/AGENTS.md`

Verified: files deployed correctly, content matches source.

## Proofs Status

| ID | Assumption | Status | Evidence |
|----|-----------|--------|----------|
| G1 | Workspace skills from `.agents/skills/` | ✅ PASS | Wrote AGY_SKILL_7M3K9 to answer.txt after reading skill |
| G2 | AGENTS.md loaded from project root | ✅ PASS | Wrote AGY_AGENTS_4R8W2 from project AGENTS.md |
| G3 | GEMINI.md overrides AGENTS.md | ✅ PASS | Wrote GEMINI_WINS_3Z9P4 (not AGENTS_WINS_1X5Y7) |
| G4 | Skills NOT loaded for unrelated queries | ✅ PASS | Answered "4" without leaking AGY_MINERAL_6V2J8 |
| G5 | Global ~/.gemini/AGENTS.md loaded | ✅ PASS | Listed P1-P9 from crew-research steering in global AGENTS.md |

**Run date:** 2026-06-14, agy v1.0.8, Gemini 3.5 Flash

## Session Analysis

### stdout Capture: BLOCKED (Issue #76)

`agy --print` writes to the TUI console handle directly, **not stdout**. When stdout is not a TTY (pipe, redirect, subprocess), output is silently dropped — exit 0, zero bytes. Confirmed bug: [google-antigravity/antigravity-cli#76](https://github.com/google-antigravity/antigravity-cli/issues/76). No fix shipped as of v1.0.8.

**Impact:** Cannot use agy as an eval harness subject (no capturable output for judge scoring).

### Available Data Sources

| Source | Content | Access |
|--------|---------|--------|
| `--log-file <path>` | Tool calls, auth, timing, errors. NOT response text. | Direct flag |
| SQLite conversation DB | Protobuf-encoded trajectory steps, metadata | `~/.gemini/antigravity-cli/conversations/{cascade_id}.db` |
| Live RPC (trajectory extractor) | Decoded steps, transcript, generator_metadata as JSON/Markdown | Requires running Antigravity process |

### Trajectory Extractor (Best Path)

[jijiamoer/antigravity-trajectory-extractor](https://github.com/jijiamoer/antigravity-trajectory-extractor) — Python tool that:
1. Discovers `cascade_id` values from local conversation cache (`~/.gemini/antigravity/conversations/*.pb`)
2. Connects to running Antigravity `language_server` process on localhost
3. Fetches decoded trajectories via RPC: `GetCascadeTrajectory`, `GetCascadeTrajectorySteps`, `GetCascadeTrajectoryGeneratorMetadata`
4. Exports as Markdown or JSON (includes steps, transcript, metadata)

**Requirements:** Antigravity process running, macOS/Linux RPC discovery (Windows untested).

### Capability Matrix

| Capability | Status | Method |
|-----------|--------|--------|
| Non-interactive execution | ✅ | `agy --print` (output to console only) |
| Capture output programmatically | ❌ Issue #76 | No stdout in non-TTY |
| Proof validation | ✅ Workaround | Ask agent to write answer to file |
| Session log analysis (tools) | ⚠️ Partial | `--log-file` shows tool approvals, not text |
| Session transcript extraction | 🔬 Spike needed | Trajectory extractor via live RPC |
| Eval harness integration | ❌ Blocked | Can't capture output for judge scoring |

| Aspect | kiro-cli | Codex | agy |
|--------|----------|-------|-----|
| Skills path (global) | `~/.kiro/skills/` | `~/.agents/skills/` | `~/.gemini/antigravity-cli/skills/` |
| Skills path (project) | `.kiro/skills/` | `.agents/skills/` | `.agents/skills/` |
| Steering (global) | `~/.kiro/steering/*.md` | `~/.codex/AGENTS.md` | `~/.gemini/AGENTS.md` + `~/.gemini/GEMINI.md` |
| Steering (project) | `AGENTS.md` | `AGENTS.md` | `AGENTS.md` + `GEMINI.md` |
| Non-interactive | `--no-interactive` | `codex exec` | `--print` |
| Binary | `kiro-cli` | `codex` | `agy` |

## Shared Observations

- agy and Codex both use `.agents/skills/` for workspace-level skills (same path!)
- AGENTS.md is the universal cross-tool context file (all 3 tools read it)
- Skill format is converging: all use markdown with name/description frontmatter
