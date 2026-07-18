# AGENTS.md

## Project

crew-research — Source repo for portable AI coding skills. Skills are authored here, tested via evals, then deployed to user projects via `mise run init`.

## Workspace Layout

```
atomics/skills/{slug}/SKILL.md    — Skill source (agent-loadable, <100 lines)
atomics/skills/{slug}/references/ — Progressive-loading companion files
atomics/eager-context/            — Always-on context modules
compositions/tiers/{name}.yaml    — What ships in each tier (inc. extensions)
compositions/project-level.yaml   — Per-project installable skills (lint membership)
compositions/agent-archetypes/    — Agent role manifests (skills, tools, prompt)
compositions/crew-patterns/       — Multi-agent crew manifests
compositions/workspace-conventions/ — File/folder contracts
tools/generator/                  — init.sh, doctor.sh, catalog.sh, generate.sh, release.sh
tools/evals/                      — Eval harness, definitions, fixtures, experiments
tools/proofs/                     — Platform assumption tests
tools/lint/                       — Cross-link validation
tools/recall/                     — Cross-session memory CLI tool (extension)
tools/recall/ingest-all.sh        — Scheduled recall ingestion (all projects + sessions)
tools/recall/bashrc-hook.sh       — WSL .bashrc staleness checker (source of truth)
tools/session-analyzer/           — Session transcript parsing
.memory/CONTEXT.md                — Project glossary (update on term resolution)
.memory/adr/                      — Architecture decisions
.memory/specs/                    — Lasting technical specs
.kiro/skills/                     — Project-local tooling guides (eval-harness, session-analysis, deploy-toolkit, release-protocol, tool-installation)
.tickets/                         — Ticket files (frontier-work; NN-slug.md with status/blocked_by)
.scratch/                         — Ephemeral (handoffs, active plans)
docs/                             — Research history (eval results, experiment plans)
docs/development/                 — Practices, spike records, results
.references/                      — Local reference repos (gitignored)
```

## Commands

```bash
# Deployment
mise run init -- --project <path> --tier basic --tool kiro-cli
mise run init -- --global --tier basic --tool kiro-cli
mise run init -- --skip-extension recall   # deploy without recall
mise run catalog
mise run doctor -- --project <path>
mise run validate-deployment

# Development
mise run validate                    # compositions + cross-links
mise run generate -- --tool kiro-cli --output ./deploy
mise run lint                        # practice↔skill cross-links

# Evaluation
mise run eval                        # all dual-run evals
mise run eval:one -- <definition>    # single eval
bash tools/evals/harness/run.sh --all --skip-completed <results-dir>  # resume an interrupted run into one dir
mise run eval:activation             # skill activation tests (gates: TPR≥0.5, FPR≤0.2; env-overridable; retired/ excluded)
mise run eval:qualitative -- <name>  # keyword-based experiment
mise run session:parse 30            # parse session transcripts (days required)
mise run session:skills 30           # skill activation + steering compliance report (days required)

# Recall (cross-session memory)
mise run recall:ingest               # ingest all projects + sessions
mise run recall:status               # show indexed content
recall search "query"                # semantic search
recall import .memory/ --wing name   # import a single project's knowledge

# Release (versioning: SemVer, tags + CHANGELOG — see release-protocol skill)
mise run release -- <version> --dry-run   # preview
mise run release -- <version>             # changelog roll, tag, push, GH release
```

## Windows / WSL Deployment

On Windows, run deployment via WSL bash (bypasses PowerShell PATH issues):

```bash
# Deploy all tools via WSL
wsl -- bash -c "export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$PATH && \
  cd /mnt/c/Users/\$USER/code/crew-research && \
  bash tools/generator/init.sh --global --tier full --tool kiro-cli --tool codex --tool agy"

# Trust mise.toml after cloning (Windows mise)
mise trust C:\Users\<user>\code\crew-research\mise.toml

# Prerequisites (WSL)
sudo curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  -o /usr/local/bin/yq && sudo chmod +x /usr/local/bin/yq
curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install ./tools/recall
```

**Staleness hooks** ensure recall ingestion runs on shell open if >4h stale:
- PowerShell: `Invoke-RecallIngestIfStale` in `$PROFILE` — fires WSL ingestion as background job
- WSL: `_recall_ingest_if_stale` in `~/.bashrc` — fires nohup background ingestion
- Source of truth for the WSL hook: `tools/recall/bashrc-hook.sh`

## Recall Operations

```bash
# Manual full ingestion (all projects + sessions)
bash ~/.local/bin/recall-ingest-all.sh
# or: mise run recall:ingest

# Check what's indexed
recall status

# Search memory
recall search "what did we decide about X"

# Add a new project to automatic ingestion
# Edit tools/recall/ingest-all.sh → add to PROJECTS array
# Then: cp tools/recall/ingest-all.sh ~/.local/bin/recall-ingest-all.sh

# Schedule: WSL cron runs every 4h
# Staleness hooks in PowerShell profile + .bashrc trigger on shell open if >4h stale
```

## Skill Authoring Rules

- `atomics/skills/{slug}/SKILL.md` — primary file, <100 lines
- YAML frontmatter: `name`, `description`, `metadata.type`, `metadata.invocation`, `metadata.practice`
- `description` field doubles as activation trigger — use distinctive keywords
- Companion files in `references/` load progressively (only when needed) — for STEERING skills, deploys place them in the tool's skills tree with links rewritten, never under `steering/references/` (ADR 0009)
- Practices in `docs/development/` are source research; skills are distilled deployment
- Cross-link: skill declares `practice: slug`, practice declares `skills: [slug]`
- **Retiring a skill:** add it to `compositions/deprecated.yaml` (name, replaced_by, reason, since) in the same commit that deletes it — deploys prune retired names from user machines; lint blocks name reuse

### Eval-Proven Patterns

- **Gates > suggestions** — mandatory checklists with "fix before presenting" produce consistent behavior; optional advice doesn't
- **Target unprompted behavior** — skills that enforce what the model WON'T do unprompted show delta; skills encoding what it already does when asked show none
- **Variance reduction is the value** — a skill that raises the floor (1→4) matters more than one that raises the ceiling (4→5)
- **Steering pointers for customization** — inject domain knowledge via pointer + manual-inclusion detail file instead of forking skills (see ADR 0002)
- **Cross-model gap** — skills tested on one model (Claude) may behave differently on another (GPT-5.x, Gemini). Process instructions can conflict across models. Run key evals on multiple tools before assuming universality.

## Conventions

- **Glossary**: `.memory/CONTEXT.md` — update immediately when terms resolve
- **ADRs**: `.memory/adr/NNNN-slug.md` — hard-to-reverse decisions only
- **Scratch**: `.scratch/` — ephemeral; promote to `.memory/` or delete
- **Tiers**: `compositions/tiers/{name}.yaml` — structured skill references
- **Results**: `tools/evals/results/` — gitignored, kept locally

## Issue Triage

When processing GitHub issues:

**Bug reports:**
1. Reproduce with `mise run doctor` output if provided
2. Check if the skill/steering file exists and is correctly deployed
3. Fix in `atomics/skills/` or `tools/generator/`, run `mise run validate`
4. Reference the issue in commit: `fix(scope): description (fixes #N)`

**Feature requests:**
1. Check if an existing skill already covers the request (run `mise run catalog`)
2. If new skill needed: draft in `atomics/skills/{slug}/SKILL.md`, add to appropriate tier
3. If enhancement: modify existing skill, keep <100 lines
4. Add eval definition if behavior is measurable

**Labels:** `bug`, `enhancement`, `skill-request`, `steering`, `tooling`

## Constraints

- Do NOT modify files in `.references/` (read-only)
- Do NOT put implementation details in CONTEXT.md (glossary only)
- Do NOT create skills over 100 lines without justification
- Do NOT mix user docs and agent-loadable content in the same file
- Do NOT track eval results in git (gitignored)
