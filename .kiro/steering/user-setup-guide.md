# User Setup Guide

When a user asks about setting up crew-research, installing skills, or getting started, follow this flow.

## Decision Flow

```
"What is this?" → Explain: portable skills that improve AI coding assistants
"How do I use it?" → Guide through tier selection + init
"What tier?" → Ask about their workflow, recommend basic unless they need crews/research/creative
"Something isn't working" → Run doctor, check output
```

## Tier Recommendation

Ask: "What does your workflow look like?"

- **Building and shipping code** (plan, build, review, test, deploy) → `basic`
- **Full development lifecycle** (also research, architecture, docs, deployment safety) → `full`

Both tiers are global. **Project-level specialist skills** (creative, prototyping, meta) install per-project — suggest them during init or when you detect matching work.

## Setup Steps

1. **Ensure prerequisites**: `kiro-cli` 2.3.0+, `yq`, `mise` (optional but recommended)
2. **Run init**:
   ```bash
   mise run init -- --project ~/their-project --tier basic --tool kiro-cli
   ```
3. **Verify**: `mise run doctor -- --project ~/their-project`
4. **Explain what was deployed**:
   - `.kiro/steering/` — always-on rules (code hygiene, verification)
   - `.kiro/skills/` — on-demand knowledge (activates when relevant, invocable via `/name`)
   - `.memory/CONTEXT.md` — project glossary (they should add terms as they work)
   - `AGENTS.md` — agent-facing project reference

## After Setup

Teach the user these workflows:
- **Starting a session**: `/read-handoff` (if continuing prior work)
- **Planning work**: just describe what they want — `planning-cycles` activates automatically
- **Stress-testing a design**: `/grill-with-docs`
- **Ending a session**: `/handoff`
- **Periodic cleanup**: `/workspace-cleanup`

### Personal Global Steering & Skills (symlink convention)

Files added directly to `~/.kiro/steering/` that aren't in the deployed tier get **PRUNED on the next deploy**. To add personal always-on steering that survives redeploys, symlink it — init.sh's prune preserves symlinks:

```bash
ln -s ~/my-notes/my-conventions.md ~/.kiro/steering/my-conventions.md
```

`~/.kiro/skills/` is safer: init.sh prunes only skills it deployed itself (tracked in `~/.kiro/.crew-skills`); unmanaged skill dirs are warned about but kept. Still, **symlinks are the recommended convention for other projects deploying skills globally** — ownership is explicit and the deployed skill stays live with its source repo:

```bash
ln -s ~/code/my-project/skills/my-skill ~/.kiro/skills/my-skill
```

`mise run doctor` warns about unmanaged regular files (steering) and unmanaged skill dirs.

### Customizing Global Skills

If a global skill needs project-specific knowledge (domain questions, source priorities, cross-reference targets), use a **steering pointer** instead of forking the skill:

1. Create `.kiro/steering/pointer-file.md` (always-loaded, ~2 lines): "Before starting [skill], read [detail file]"
2. Put the detail content in `.kiro/skills/<name>/SKILL.md` (or a `references/` file there) — the skills tree is the non-eager zone. Do NOT place detail files under `.kiro/steering/` — everything there loads on every turn regardless of `inclusion:` markers (ADR 0009); `steering/references/` is reserved for user-owned always-on files
3. The global skill runs unmodified; the agent reads the detail file on demand when the skill activates

This costs ~50 characters of always-loaded context vs thousands for a full skill copy. See ADR 0002 for when to use params vs pointers vs extends.

### Known Tools (external, self-deploying)

Known tools are separately-owned repos whose skills integrate with crew-research deployments. Unlike extensions, crew-research does not deploy their content — they self-deploy (symlink convention), and crew-research detects them, lists them in `mise run catalog`, and checks their health in `mise run doctor`. Registry: `compositions/known-tools.yaml`.

| Tool | What it adds | Hydrate |
|------|-------------|---------|
| `archwright` | Design methodology pipeline (forces → tensions → resolution → verified architecture) | `git clone <archwright-repo> ~/code/archwright && bash ~/code/archwright/tools/deploy-skills.sh` |

**When to suggest archwright:** recurring design tensions, specs that need mechanical verification, architecture decisions that should carry traceable provenance. Adjacent skills (architecture-deepening, spec-driven-development, planning-cycles, grill-with-docs, adr-authoring) carry conditional recommendation seams — they route to archwright only when its skills are actually deployed.

**Ownership boundary:** archwright's skills/steering are authored in its repo; crew-research never copies them. If `doctor` reports broken archwright symlinks, the repo moved — re-run its deploy script.

### Extensions (Auto-Deploy)

Extensions add capabilities that require external tools. They deploy automatically when prerequisites are met during tier deploy.

```bash
uv tool install ./tools/recall            # install from a crew-research clone
uv tool install -e ./tools/tkt            # editable — tracks the checkout live
mise run init -- --global --tier basic    # recall auto-activates
mise run init -- --skip-extension recall  # opt out if desired
```

| Extension | What it adds | Prerequisite |
|-----------|-------------|--------------|
| `recall` | Cross-session memory — remembers decisions, past work, preferences | `recall` CLI on PATH |

**When to suggest recall:** If the user works on long-lived projects, frequently resumes work across sessions, or asks about past decisions.

**When to suggest tkt:** If the user works on multi-session features, uses `.tickets/` for work tracking, or asks about ticket management. `tkt` is the purpose-built ticket CLI for the `.tickets/` contract — it handles dependency graphs, frontier detection, ID allocation races, and plan sync.

**Install both (recommended for full tier):**
```bash
uv tool install ./tools/recall   # from a crew-research clone (PyPI "recall" is a squatted unrelated package)
uv tool install -e ./tools/tkt   # editable — tracks the checkout live; reinstall only after entry-point/metadata changes
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Skills not activating | Check `mise run doctor`; verify `.kiro/skills/` has SKILL.md files |
| "Command not found" for mise | `mise` is optional; they can run `tools/generator/init.sh` directly |
| Want to add more skills later | `mise run catalog` to browse, then re-run init with `--tier full` |
| Steering feels too aggressive | Remove specific `.kiro/steering/*.md` files they don't want |
| mise config not trusted (Windows) | Run `mise trust` in the project directory |
| yq not found (Windows/WSL) | `sudo curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq` |

## Windows / WSL Setup

On Windows, crew-research deploys via WSL bash. The init script auto-detects WSL and writes to the Windows home (`C:\Users\<user>\`) so all tools can read the files.

### Prerequisites (WSL)

```bash
# yq (YAML processor — required by init.sh)
sudo curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
```

### Deploy

```powershell
# Run from PowerShell. Single quotes are load-bearing: with double quotes
# PowerShell expands $USER/$HOME/$(...) itself and the deploy silently degrades.
# Corp machines (CREW_ENV=corp): kiro-cli + codex only (no agy — company policy).
# Personal machines: add --tool agy.
wsl -- bash -c 'export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH" && cd /mnt/c/Users/$USER/code/crew-research && bash tools/generator/init.sh --global --tier full --tool kiro-cli --tool codex'

# If your WSL username differs from your Windows username, resolve it first:
wsl -- bash -c 'WIN_USERNAME=$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d "\r") && export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH" && cd /mnt/c/Users/$WIN_USERNAME/code/crew-research && bash tools/generator/init.sh --global --tier full --tool kiro-cli --tool codex'
```

### After Deploy (Windows side)

```powershell
# Trust mise.toml so mise stops showing errors
mise trust C:\Users\<user>\code\crew-research\mise.toml
```

### Recall Setup (Native Windows — no WSL needed)

Recall runs natively on Windows. No WSL, cron, or .bashrc hooks required.

```powershell
# Install recall (from a crew-research clone — PyPI "recall" is squatted)
uv tool install .\tools\recall

# Manual ingestion (discovers all projects under ~/code)
pwsh -File tools\recall\Invoke-RecallIngestAll.ps1

# Scheduled Task (every 4h, replaces cron)
$action = New-ScheduledTaskAction -Execute "pwsh.exe" `
  -Argument "-NoProfile -NonInteractive -File `"$env:USERPROFILE\code\crew-research\tools\recall\Invoke-RecallIngestAll.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName "RecallIngest" -Action $action -Trigger $trigger -Settings $settings

# Profile hook (fires on shell open if >4h stale)
# Add to $PROFILE:
. C:\Users\<user>\code\crew-research\tools\recall\profile-hook.ps1
```

### Recall Setup (Linux/macOS)

```bash
# Install
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install ./tools/recall   # from local clone

# .bashrc staleness hook (fires on shell open if >4h stale)
cat tools/recall/bashrc-hook.sh >> ~/.bashrc
```
