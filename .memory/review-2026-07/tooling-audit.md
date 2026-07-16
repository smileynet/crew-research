# Tooling Audit: generator/ lint/ proofs/

Date: 2026-07-16 · Auditor: r6-generator-lint-proofs session
Method: read all scripts, `bash -n` syntax checks (all 8 scripts pass), read-only runs of catalog/doctor/lint/generate-validate, one generate run to a temp dir (deleted after).

## Summary Table

| Tool | Verdict | Top issue |
|------|---------|-----------|
| generator/init.sh | HEALTHY (cosmetic cleanup) | Leftover empty PLUGIN comment block; dead `--language` flag |
| generator/doctor.sh | NEEDS-FIX | No extension/eval-steering/recall-ingest checks; dead var; GNU-only grep |
| generator/catalog.sh | NEEDS-FIX | Dead prompt/tier/category logic; no extensions or full-tier tags |
| generator/generate.sh | NEEDS-FIX (generate mode is broken) | `PROJECT_CONFIG: unbound variable` crash on any `generate` run |
| lint/check-crosslinks.sh | DEAD (functionally) | Validates a structure that no longer exists; passes vacuously; no frontmatter check |
| proofs/harness/run.sh | NEEDS-FIX | inspect-session.sh not executable → log checks silently no-op; ignores `adapter:` and `setup:` in newer definitions |
| proofs/harness/run-proof.sh | HEALTHY (minor dead code) | `DEFS_DIR` declared, never used (S1–S4 queries hardcoded) |
| proofs/adapters + definitions | NEEDS-FIX (schema drift) | Two incompatible definition schemas; adapters missing fields run.sh requires |

---

## 1. generator/init.sh — HEALTHY (cosmetic cleanup)

**ADR-0008 verdict: plugin removal is functionally complete.** No `--plugin`, `--remove-plugin`, `plugins.json`, or `compositions/plugins/` references remain (verified via `grep -rn -i plugin` across tools/ and compositions/; `compositions/plugins/` directory is gone). Extensions logic (lines 60–92) implements the ADR-0008 design: prerequisite test, `--skip-extension`, merged into the single DESIRED prune loop.

Issues:

- **Lines 48–52 — leftover PLUGIN section header.** An empty boxed comment block `# PLUGIN INSTALL / REMOVE` with nothing under it. Pure dead scaffolding from the removed code. Delete.
- **Lines 18, 30, 408–418 — dead `--language` flag.** `LANGUAGE` is parsed and set by language detection but never consumed anywhere (not in the AGENTS.md heredoc, not in any deploy path). Remove the flag and assignments, or wire it into the scaffold.
- **Lines 19–21 — `BUILD_CMD`/`TEST_CMD`/`LINT_CMD` initialized at top** but only meaningful in the project-scaffold branch (set at lines 407–419, used in AGENTS.md heredoc line ~455). Not dead, but the top-level init + no CLI flags for them is a residue of an older interface. Cosmetic.
- **Line ~231 — `prompts/` prune** ("migrated to skills") is a migration shim; fine to keep for now, candidate for removal once fleets are migrated.
- **Note:** ADR-0008 mentions an `--extension` (force opt-in) flag; init.sh implements only `--skip-extension`. Gap vs ADR, not a bug (auto-detect covers the common case).

## 2. generator/doctor.sh — NEEDS-FIX

Ran read-only: exits 0, "Healthy" on this repo. What it checks: kiro-cli/yq/jq presence, global steering/skill counts, unresolved `{{params}}`, codex/agy deployment (only if `CREW_TOOLS` set), project workspace files, CONTEXT.md emptiness, .gitignore, recall wing import, project steering overrides, shadowing prompts/.

**What it misses:**

- **Extensions (per ADR-0008): no check.** It never reads the tier manifest's `extensions:` section. If `recall` CLI is installed but the recall extension steering/skills (`recall-session-start.md`, `recall-check.md`, `skills/recall/`) failed to deploy, doctor says Healthy. It should compare deployed files vs `tier manifest + passing prerequisites`.
- **No tier-manifest reconciliation at all.** It only counts files (`skill_count -gt 0`, lines 35–43). A half-pruned or stale deployment with 5 of 12 skills reads as ✅. Compare against `compositions/tiers/$TIER.yaml`.
- **Eval steering: no check.** Project-local steering like `.kiro/steering/eval-execution.md` is only counted generically (line ~135, "N project-specific steering override(s)"), never validated.
- **Recall ingest staleness / cron: no check.** The `recall-session-start` steering depends on `~/.recall/last_ingest` being <24h old (implying a cron or regular `recall ingest`). Doctor checks wing import counts (lines 118–130) but never checks `~/.recall/last_ingest` freshness or that any scheduled ingest exists.
- **Line 121 — dead variable.** `imported=$(recall status ... | grep -c "import:")` is assigned and never used.
- **Line 123 — `grep -oP`** (PCRE) is GNU-only; breaks on macOS/BSD grep. The README advertises macOS support. Use `sed -n 's/.*(\([0-9]*\)).*/\1/p'` or awk.
- **Tool checks don't cover codex/agy/mise binaries** even when `CREW_TOOLS` includes them — it checks their deployment artifacts but not the CLIs themselves (check_tool is only called for kiro-cli/yq/jq, lines 28–31).
- **No SKILL.md frontmatter validation** on deployed skills (see lint section — this gap is systemic).

## 3. generator/catalog.sh — NEEDS-FIX

Runs fine read-only. Issues:

- **Lines 11–12 — `--tier` parsed, never used.** `TIER` is captured and then ignored; catalog always lists everything.
- **Line 3 — `--category` advertised in usage, not parsed at all.**
- **Lines 30, 39–40 — dead `prompts` logic.** Tier manifests contain only `description/steering/skills/extensions` (verified with `yq 'keys'`). The `[basic/prompt]` tag branch can never fire, and the summary prints "0 prompts" / "0 agents" noise. Also no `agents:` key exists in full.yaml.
- **No extensions display.** Extension-gated skills (e.g., `recall`) show with no tag; catalog predates ADR-0008.
- **No `[full]` tag** — skills only in the full tier show untagged, indistinguishable from unshipped skills.

## 4. generator/generate.sh — NEEDS-FIX (generate mode broken)

- **`validate` mode works:** ran read-only → "✅ All references resolve (21 files)", exit 0.
- **`generate` mode crashes.** Verified live: `bash tools/generator/generate.sh generate --tool kiro-cli --output /tmp/...` → `line 245: PROJECT_CONFIG: unbound variable`, exit 1. `PROJECT_CONFIG` is referenced at lines 84, 92, 123, 218, 245 but **never assigned anywhere** — under `set -u` the first non-conditional-guarded reference (line 245, `[[ -n "$PROJECT_CONFIG" ...]]`) aborts. The `--project` flag sets `PROJECT` (line 23), not `PROJECT_CONFIG`. Fix: initialize `PROJECT_CONFIG=""` (or derive from `$PROJECT`).
- **Line 31 — `PROJECT_CREWS=""` assigned, never used.** Dead.
- **Architecture drift:** generate.sh still targets `claude-code` and the crews/archetypes model (`.kiro/agents/*.json`, CLAUDE.md appends), while init.sh is the actual deployment path (kiro-cli/codex/agy). The AGENTS.md said `mise run generate -- --tool kiro-cli --output ./deploy` is a supported command — it currently cannot succeed. Either fix the unbound var and keep it as the crew-generation path, or mark it deprecated.

## 5. lint/check-crosslinks.sh — DEAD (functionally)

Ran read-only: `Errors: 0 | Warnings: 0`, exit 0 — but it validated **nothing**:

- **Section 1 (lines 20–37, practices→skills):** `PRACTICES_DIR=$ROOT_DIR/docs/practices` **does not exist** (verified). The loop iterates zero files. Practices now live in the external best_practices repo (skills reference them as "Source practice: ... (in best_practices repo)").
- **Sections 2–3 (lines 41–75, skills→practices + staleness):** 39 of 40 skills declare `practice: null` (verified via grep), and the script skips null. Nothing is checked.
- **Does NOT validate SKILL.md frontmatter exists.** Confirmed live gap: `atomics/skills/multi-agent-validation/SKILL.md` currently has **no frontmatter** (first line is not `---`) and every tool passes it silently — this is exactly the "skill shipped without frontmatter" incident class. Neither lint, nor `generate.sh validate`, nor doctor catches it.

**Recommendation:** repurpose this script as a skill-structure lint:
1. Every `atomics/skills/*/SKILL.md` starts with `---` and has parseable YAML frontmatter containing `name` + `description` (and `metadata.type`/`metadata.invocation` per AGENTS.md rules).
2. `references/` companion files referenced from SKILL.md bodies exist (and vice versa: orphan references warning).
3. SKILL.md line count <100 (AGENTS.md constraint) as a warning.
4. Tier manifests reference only existing skill slugs (currently nothing checks `compositions/tiers/*.yaml` entries — init.sh silently skips missing dirs at deploy time).
Drop or keep the practice check behind a `[[ -d $PRACTICES_DIR ]]` guard.

## 6. proofs/ — NEEDS-FIX (schema drift + silent log-check no-op)

### Inventory

- **Adapters (6):** kiro-cli, claude-code, codex, agy, crush, closecode. All parse as YAML.
- **Definitions (15):** A1, A3, A4, A5 (kiro assumptions); C1–C4 (codex); G1–G5 (agy/gemini); S1–S4 (subagent reliability).
- **Harness (3):** `run.sh` (definition runner), `run-proof.sh` (hardcoded S1–S4 subagent proofs), `inspect-session.sh` (session-log assertions). All three pass `bash -n`.

### run.sh issues

- **Line 278 — inspect-session.sh is NOT executable** (`-rw-r--r--`, verified). The call `$("$SCRIPT_DIR/inspect-session.sh" $inspect_args)` fails with permission denied, is swallowed by `|| true`, and the "Permission denied" output matches neither `FAIL:` nor `SKIP:` — so **all `log_checks` (used by 11 of 15 definitions) silently pass without running**. Fix: `chmod +x` or invoke via `bash "$SCRIPT_DIR/inspect-session.sh"`.
- **Ignores the definition `adapter:` field.** G1 declares `adapter: agy`, S1 `adapter: kiro-cli`, but `--all` runs every definition against whatever `--adapter` is given. Cross-tool runs produce guaranteed-failing noise.
- **Ignores `setup:`/`teardown:`/`manual_steps:`/`pass_criteria:` keys.** S1–S4 and G1–G5 have **zero `fixtures`** (verified: `grep -c fixtures` = 0 for all nine) — run.sh deploys nothing for them, then invokes the query in an empty temp dir. These are effectively manual-procedure definitions being run as if automated.
- **Line 237 — `cd "$workdir"` without returning**; safe today because all subsequent paths are absolute, but fragile.
- **Adapter schema gaps:** run.sh requires `.agent.format/.agent.location` (lines 45–46), `.eager_context.location` (line 48), and `.invoke.command_no_agent` (line 43). Only kiro-cli and claude-code have `agent` + `eager_context` + `command_no_agent`; codex has `command_no_agent` only; **agy, crush, closecode lack `command_no_agent`** — a fixture-less definition against those adapters substitutes into the literal string "null". agy/codex/closecode also lack `eager_context`.

### run-proof.sh — HEALTHY (minor)

Self-contained S1–S4 runner with hardcoded fixtures/queries; parses and its logic is coherent (isolated KIRO_HOME, inline-vs-fileread variants, canary grading).
- **Line 8 — `DEFS_DIR` assigned, never used.** The S1–S4 YAML definitions are decorative for this script; the real proof spec is hardcoded here. Duplication risk: S-definitions in `definitions/` can drift from what run-proof.sh actually executes.

### Definitions — two schemas coexist

- Schema A (automatable, run.sh-compatible): A1/A3/A4/A5, C1–C4 — `fixtures` + `expect` (+ `log_checks`).
- Schema B (manual/hybrid): S1–S4, G1–G5 — `adapter`/`setup`/`pass_criteria`/`manual_steps`, no fixtures.
Recommendation: make run.sh (a) skip definitions whose `adapter` doesn't match, (b) refuse (SKIP, not run) definitions with `setup:` but no `fixtures:`.

---

## Prioritized Fix List

1. **lint:** add SKILL.md frontmatter-exists validation (live failure today: `multi-agent-validation`); guard/retire dead practice checks. Also fix `multi-agent-validation/SKILL.md` itself.
2. **generate.sh:245:** initialize `PROJECT_CONFIG=""` (one-line fix for a hard crash) — or deprecate generate mode explicitly.
3. **run.sh:278:** `bash`-invoke or chmod +x inspect-session.sh; make log-check invocation failure a FAIL, not silence.
4. **doctor.sh:** add extension-vs-manifest reconciliation, recall `last_ingest` staleness, tier-manifest skill-count comparison; remove line-121 dead var; replace `grep -oP`.
5. **init.sh:48–52:** delete empty PLUGIN comment block; remove dead `--language`.
6. **catalog.sh:** remove prompts/agents logic; add extension + full-tier tags; implement or drop `--tier`/`--category`.
7. **run.sh:** respect definition `adapter:` field; skip fixture-less definitions.
# Tooling Audit: recall / session-analyzer / okf-bundle

Date: 2026-07-16 · Ticket R6 · Auditor: r6-recall-analyzer-okf

## Summary

| Tool | Verdict | Headline |
|------|---------|----------|
| `tools/recall/` | **NEEDS-FIX** | Installed CLI is stale (missing `import` cmd, v3 ingest, `--type` filter); PyPI name `recall` is taken by an unrelated package |
| `tools/session-analyzer/` | **HEALTHY** | Schema matches live session files; 2,956 v2 files present |
| `tools/okf-bundle/` | **DEAD** (unused prototype) | No code consumers, no generated bundles exist, not in mise tasks |

---

## 1. recall/ — NEEDS-FIX

### Entry points read
`pyproject.toml`, `recall/cli.py` (main entry, `recall.cli:main`), `recall/__init__.py`, `spike/FINDINGS.md`.

### Version consistency — OK (but fragile)
- `pyproject.toml` version: `0.1.0`
- `recall/__init__.py` `__version__`: `0.1.0`
- Installed CLI: `recall 0.1.0` (verified: `recall --version` → `recall 0.1.0`)
- **Fragility:** version is hardcoded in THREE places — pyproject, `__init__.py`, and the argparse `--version` string in `cli.py`. Substantive code changes landed Jul 10 (v3 ingest, `import` command, `--type` filter) with no version bump. Any of the three can silently drift.

### Installed package vs repo — STALE (the real problem)
- Install source: `direct_url.json` → `file:///local/home/sabiggin/code/crew-research/tools/recall` (local uv tool install, NOT PyPI)
- `diff -rq` installed site-packages vs repo: **4 of 6 modules differ** (`cli.py`, `chunker.py`, `normalize.py`, `store.py`)
- Installed `cli.py` has **zero occurrences of `cmd_import`** — the `recall import` command does not exist in the installed CLI, yet:
  - `~/.kiro/steering/recall-*.md` and README instruct users to run `recall import .memory/ --wing X`
  - Installed CLI also lacks v3 session ingest (`*/sess_*/messages.jsonl`) and `search --type`
- **Fix:** `uv tool install --reinstall /local/home/sabiggin/code/crew-research/tools/recall` (and bump version to reflect the new commands)

### PyPI-installable path — BROKEN CLAIM
- `curl https://pypi.org/pypi/recall/json` → HTTP 200, but the package is **"Python High performance RPC framework based on protobuf" v0.2.1 by Yaolong Huang** — an unrelated squatted name.
- README.md and user-setup-guide say `uv tool install recall # from PyPI` — following that instruction installs the **wrong package**.
- **Fix:** either publish under a unique name (e.g. `crew-recall`, `kiro-recall`) and update docs, or remove the PyPI claim and document local-path install only.

### spike/ dir — KEEP (with optional relocation), not stale garbage
- Contents: 8 model spike scripts, harness, 7 results JSONs, `FINDINGS.md` (2026-06-20).
- `FINDINGS.md` is the empirical basis for the shipped embedding model choice and is **cross-referenced by ADR 0007** (`.memory/adr/0007-purpose-built-recall-tool.md` cites "won empirical spike against 7 models"). The production `embedder.py` and `store.py` encode its decision (`bge-base-en-v1.5-int8`).
- The scripts are the reproducibility evidence for that decision; total size is trivial (~50KB).
- **Recommendation:** keep `FINDINGS.md` (or promote it to `docs/development/` per AGENTS.md convention "spike records"); the spike scripts + results JSONs may be pruned or archived if desired, but they are documented evidence, not orphaned code. Do NOT delete FINDINGS.md.

---

## 2. session-analyzer/ — HEALTHY

### Entry point read
`parse.py` (14.5KB, full read). Also present: `extract_batches.py`, `README.md`.

### Expected format
Dual-format parser:
- **v2:** `~/.kiro/sessions/cli/*.jsonl`, events keyed by `kind` ∈ {`Prompt`, `AssistantMessage`, `ToolResults`} with a `data` object (`data.content[]`, `data.meta.timestamp`, toolUse entries).
- **v3:** `~/.kiro/sessions/<hash>/sess_*/messages.jsonl`, events keyed by `payload.type` ∈ {`user`, `assistant`, `tool_use`, `tool_result`} + top-level `timestamp`.

### Live verification
- v2 files exist: **2,956** files in `~/.kiro/sessions/cli/*.jsonl`
- v3 files: **0** (glob `*/sess_*/messages.jsonl` matched nothing — v3 path is dormant/forward-looking, harmless)
- Sample read (`9868e916-...jsonl`, most recent): top-level keys `['data', 'kind', 'version']`; line kinds observed: `Prompt` (data keys: content, message_id, meta), `AssistantMessage` (content, message_id), `ToolResults` (content, message_id, results)
- **Schema match:** parse.py's `_parse_v2_event` reads `msg["kind"]`, `msg["data"]["content"]`, `data.meta.timestamp` — all present in the sample. ✅

### Minor notes (not blocking)
- `ToolResults` handler reads `data["content"]` for toolResult entries; sample also has a `data.results` key the parser ignores — no crash risk, possibly untapped data.
- `normalize_command()` contains Windows/PowerShell patterns (Get-ChildItem, Start-Process) — cross-platform leftovers, harmless on Linux.
- Unused import: `os` in parse.py.

---

## 3. okf-bundle/ — DEAD (unused prototype)

### Entry points read
`generate_bundle.py` (full), `SUBAGENT_PROMPT.md` (full).

### What it generates
An OKF (Open Knowledge Format) bundle **scaffold** from a reference repo: `overview.md` + `patterns/_template.md` + `conventions/_template.md` + `integrations/_template.md` + `index.md`, each with YAML frontmatter (`type`/`title`/`description`/`tags`/`timestamp`). Content is placeholder `[LLM: ...]` markers — a subagent (via `SUBAGENT_PROMPT.md`) is supposed to fill them. Also has `--scan` mode emitting a JSON manifest. Default output: `.memory/references/`.

### Reference check (grep `okf-bundle|generate_bundle` across repo)
| Reference | Real consumer? |
|-----------|---------------|
| `tools/evals/scripts/multi-project-import-eval.py` lines 33/259-260 | **No** — "okf-bundle" there is a **fixture directory name** (`tools/evals/fixtures/import-samples/okf-bundle/`), verified by reading the script context; it tests `recall import`, not this tool |
| `docs/plan.md` (ticket R6) | No — it's this audit's own ticket |
| `.memory/specs/recall-okf-integration.md` line 96 | Aspirational — claims "we already generate these via tools/okf-bundle/" |
| Self-reference in its own docstring | No |

### Evidence of non-use
- Not wired into any mise task (grep `okf` in mise config: no matches)
- `.memory/references/` is **empty** — no bundle has ever been generated/kept
- The `study-reference` / `study-all-references` skills (the natural consumers) do not invoke it
- The spec's claim of active use is contradicted by the empty output directory

### Recommendation
Two options, pick one:
1. **Delete** `tools/okf-bundle/` and correct line 96 of `.memory/specs/recall-okf-integration.md` (it overstates current capability).
2. **Wire it in**: reference `generate_bundle.py` from the `study-reference` skill so scaffolding happens during reference study — only if OKF bundle output is actually wanted.

Absent a decision, it is dead weight with a misleading spec reference.

---

## Action Items (priority order)

1. **[recall]** Reinstall the CLI: `uv tool install --reinstall /local/home/sabiggin/code/crew-research/tools/recall` — steering files instruct commands (`recall import`) the installed binary doesn't have.
2. **[recall]** Fix the PyPI claim in README.md / user-setup-guide: `uv tool install recall` installs an unrelated RPC framework. Rename for PyPI or document local install only.
3. **[recall]** Bump version (0.1.0 → 0.2.0) and consider single-sourcing it (`importlib.metadata` in the argparse version string).
4. **[okf-bundle]** Decide: delete + fix spec line 96, or wire into study-reference skill.
5. **[recall/spike]** Optionally promote `FINDINGS.md` to `docs/development/` (spike-record convention); keep it regardless — ADR 0007 depends on it.
6. **[session-analyzer]** No action needed. (Optional: drop unused `os` import.)
