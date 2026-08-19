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
compositions/known-tools.yaml     — External self-deploying tools (archwright); doctor/catalog consume
compositions/agent-archetypes/    — Agent role manifests (skills, tools, prompt)
compositions/crew-patterns/       — Multi-agent crew manifests
compositions/workspace-conventions/ — File/folder contracts
tools/generator/                  — init.sh, doctor.sh, catalog.sh, generate.sh, release.sh
tools/evals/                      — Eval harness, definitions, fixtures, experiments
tools/proofs/                     — Platform assumption tests
tools/lint/                       — Cross-link validation
tools/session-analyzer/           — Session transcript parsing
.memory/CONTEXT.md                — Project glossary (update on term resolution)
.memory/adr/                      — Architecture decisions
.memory/specs/                    — Lasting technical specs
.kiro/skills/                     — Project-local tooling guides (eval-harness, session-analysis, deploy-toolkit, release-protocol, tool-installation, proof-harness)
.tickets/                         — Ticket files (frontier-work; NN-slug.md with status/blocked_by)
.scratch/                         — Ephemeral (handoffs, active plans)
docs/                             — Research history (eval results, experiment plans)
docs/development/                 — Practices, spike records, results
.references/                      — Local reference repos (gitignored)
```

## Commands

```bash
# Tickets (tkt CLI — github.com/smileynet/tkt)
# Install: cargo install --path D:/code/tkt  (or cargo install tkt after crates.io publish)
# Single Rust binary, no runtime deps beyond git on PATH.
# Replaces the former Python implementation at tools/tkt (removed).
tkt ready                                     # frontier: env-filtered, priority-aware
tkt new <slug> --title "..." [--spec S] [--blocked-by NN,NN] [--priority high]
tkt batch <slug[:title]>... [--spec S] [--blocked-by IDS]  # N ids, ONE commit/push; lost race renumbers the group
tkt claim <id>   # status→in_progress, pushed (visible WIP; lost race names the winner)
tkt close <id> [--note "..."]  # status→done; --note writes the Resolution (else TBD stub)
tkt edit <id> [--blocked-by IDS] [--priority high|''] [--env E|''] [--spec S|''] [--title T]
tkt renumber <old> <new> [--file NAME]  # birth-window only — cited ids are contracts
tkt sync-plan --check [--strict] [--brief] [plan] # drift vs docs/plan.md (0 clean / 1 drift / 2 crash)
tkt sync-plan --fix [--strict] [--brief] [plan]   # fix derivable columns (status); report unsafe drift
tkt validate [--brief]                  # contract + decay findings (JSON, exit 0/1; --brief = one line per finding)
tkt telemetry --enable                  # opt in to local usage recording
#   .tickets/ files ARE the tkt format — tkt operates in place; no import/convert step
#   exists. Missing env: = "either" by design.
# Birth flow: `new` pushes a STUB claim immediately (id is yours once it prints
# "claimed"); write the real body afterward as a second commit.
# Works from any repo with .tickets/ (run from that repo's root).
# NOTE: `tk` on PATH is an UNRELATED third-party tool — do not use it on .tickets/
# (deps≠blocked_by, silently hides tickets with priority: high). Always tkt.

# Deployment
# CREW_ENV (gitignored .mise.local.toml) gates the tool set: corp = kiro-cli + codex
# + crush-via-Bedrock (agy policy-blocked mechanically: init refuses, doctor flags
# artifacts, harnesses exclude legs with reason "policy-blocked (CREW_ENV=corp)");
# personal adds agy. Crush/Bedrock config: deploy-toolkit references/crush-bedrock.md.
# Detail: .kiro/steering/user-setup-guide.md § Environment Designation.
mise run init -- --project <path> --tier basic --tool kiro-cli
mise run init -- --global --tier basic --tool kiro-cli
mise run init -- --skip-extension recall   # deploy without recall
mise run catalog
mise run doctor -- --project <path>
mise run validate-deployment

# Development
mise run validate                    # compositions + cross-links
mise run generate -- kiro-cli                    # or: all, claude-code
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
recall sync                          # ingest all projects + sessions
recall status                        # show indexed content
recall search "query"                # semantic search
recall import .memory/ --wing name   # import a single project's knowledge
recall health --json                 # machine-readable health (coverage, duplicates, freshness)
mise run proof:recall                # recall correctness proofs (G-K series)

# Release (versioning: SemVer, tags + CHANGELOG — see release-protocol skill)
mise run release -- <version> --dry-run   # preview
mise run release -- <version>             # changelog roll, tag, push, GH release
```

## Windows / WSL Deployment

On Windows, **only init.sh requires WSL** (the generator is bash) — everything else, including recall, runs natively. Full setup flow (yq prerequisite, the deploy command with its load-bearing single quotes, username-mismatch variant, mise trust, recall scheduled task + profile hook) is owned by `.kiro/steering/user-setup-guide.md` § "Windows / WSL Setup" — do not duplicate it here. Tool set reminder: corp machines (CREW_ENV=corp) deploy kiro-cli + codex only (no agy); personal machines add `--tool agy`.

## Recall Operations

```bash
# Install (Rust binary — single binary, no Python/venv deps)
cargo install --path ~/code/recall
# Or after crates.io publish: cargo install recall

# Manual full ingestion
recall sync                      # all projects + sessions

# Check what's indexed
recall status

# Search memory
recall search "what did we decide about X"

# Import a project's knowledge
recall import .memory/ --wing name

# Health check
recall health --json             # machine-readable (coverage, duplicates, freshness)

# Verify scheduled task (Windows)
Get-ScheduledTask -TaskName "RecallIngest" | Select State
# Linux/macOS: crontab -l | grep recall
```

## Skill Authoring Rules

- `atomics/skills/{slug}/SKILL.md` — primary file, <100 lines
- YAML frontmatter: `name`, `description`, `metadata.type`, `metadata.invocation`, `metadata.practice`
- `description` field doubles as activation trigger — use distinctive keywords
- Companion files in `references/` load progressively (only when needed) — for STEERING skills, deploys place them in the tool's skills tree with links rewritten, never under `steering/references/` (ADR 0009)
- Practices in `docs/development/` are source research; skills are distilled deployment
- Cross-link: skill declares `practice: slug`, practice declares `skills: [slug]`
- **Retiring a skill:** add it to `compositions/deprecated.yaml` (name, replaced_by, reason, since) in the same commit that deletes it — deploys prune retired names from user machines; lint blocks name reuse. Scope: deprecated.yaml covers skill NAMES only — steering and eager-context content decay is handled by guidance-sync's prune probe (P6) and `/project-audit`

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
- Do NOT set a custom agent (e.g. `recall_agent`) as `chat.defaultAgent` — custom agents restrict shell/tools; `kiro_default` uses `tools: [*]` which is correct for primary sessions

## Design Gate (archwright)

Before implementing a ticket, ask three questions (archwright must be hydrated — see known-tools):

1. **Tension** — do two forces in the ticket pull against each other (satisfying one naively violates the other)?
2. **Durable invariants** — does it create guarantees that must stay true under inputs we don't control (concurrent sessions, hand edits, future contributors)?
3. **Rejected alternatives** — will it reject a plausible approach a future session might re-propose?

Any YES → propose an archwright pipeline run before building (human decides; artifacts land in `design/`, checks gate the implementation). All NO → build directly. Can't name the forces at all → that's fog: propose a grill/discovery session, not the pipeline. Precedent: ticket 40 (3× yes → pipeline caught 2 unspiked design holes); tickets 39/42/43 (3× no → correctly skipped).

**Research before recommending:** decisions that will be recorded in a spec (rejected alternatives, revisit triggers, contract reservations) get prior-art research first — dispatch research subagents per the source-authority gates, then present recommendations WITH the findings. Reasoning-only proposals are drafts, not recommendations. Precedent: ticket 41 research reversed two consecutive positions (hash ids endorsed→rejected once GitHub alignment proved impossible by construction; title escaping planned→reject-instead once the raw-text engine's no-interpretation contract was weighed).
