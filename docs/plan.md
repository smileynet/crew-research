# Plan: Project-Wide Deep Dive Review

**Created:** 2026-07-16
**Goal:** Every skill has a clear purpose, is well organized, and follows best practices. Evals measure what matters. All project areas audited for health and relevance.

## Project Areas Inventory

| Area | Contents | Review status |
|------|----------|:-------------:|
| `atomics/skills/` | 53 skills | ✅ Ticket R1 |
| `atomics/eager-context/` | 7 always-on modules | ✅ Ticket R2 |
| `compositions/tiers/` | basic, full | ✅ Ticket R3 |
| `compositions/agent-archetypes/` | 9 archetypes | ✅ Ticket R3 |
| `compositions/crew-patterns/` | 9 patterns | ✅ Ticket R3 |
| `tools/evals/` | 75 active definitions + harness | ✅ Ticket R4, R5 |
| `tools/generator/` | init, doctor, catalog, generate | ✅ Ticket R6 |
| `tools/proofs/` | Platform assumption tests | ✅ Ticket R6 |
| `tools/lint/` | Cross-link validation | ✅ Ticket R6 |
| `tools/recall/` | Extension CLI | ✅ Ticket R6 |
| `tools/session-analyzer/` | Transcript parsing | ✅ Ticket R6 |
| `tools/okf-bundle/` | OKF bundle generation | ✅ Ticket R6 |
| `docs/development/` | 25 research docs | ✅ Ticket R7 |
| `.memory/` | 8 ADRs, 19 specs | ✅ Ticket R7 |

---

## Tickets

### R1: Skill deep-dive review (53 skills)

**Goal:** Every skill has (a) clear single purpose, (b) correct frontmatter, (c) <100 lines with references/ overflow, (d) distinctive activation description, (e) no overlap with another skill.

**Method:** Batch review via subagents (5-8 skills per stage, file-reading tasks — high reliability). Each stage produces a structured verdict per skill: KEEP / FIX (what) / MERGE (into what) / RETIRE (why).

**Checklist per skill:**
- [ ] Purpose statable in one sentence
- [ ] Description has distinctive trigger keywords (not generic)
- [ ] Frontmatter: name, description, metadata.type, metadata.invocation present
- [ ] <100 lines (or justified)
- [ ] references/ files actually referenced from SKILL.md body (no orphans)
- [ ] No content duplication with steering or other skills
- [ ] Examples/commands are current (not stale post-consolidation)

**Deliverable:** `.scratch/skill-review/verdicts.md` with per-skill table + fix list.

**Est:** 7-8 subagent stages + synthesis. ~2 hours.

### R2: Eager-context audit

**Goal:** Each always-on module earns its context cost.

- [ ] Review 7 modules: autonomy, delegation, verification, workspace, research-dispatch-mandate, permissions.yaml, hooks/
- [ ] Check: is each still deployed by generator? (some may be orphaned post-ADR-0008)
- [ ] Check overlap with tier steering (e.g., verification.md vs verification-protocol skill)
- [ ] Verify hooks/ is used by anything

**Deliverable:** Keep/retire verdict per module.

**Est:** 30 min, direct review (small corpus).

### R3: Compositions audit

**Goal:** Tiers, archetypes, and crew-patterns reference only existing skills and match post-consolidation reality.

- [ ] Validate all skill references resolve (mise run validate covers some)
- [ ] Check agent-archetypes: are they used by anything? (9 files — dispatcher, implementer, etc.)
- [ ] Check crew-patterns: same question (9 files)
- [ ] If archetypes/patterns are aspirational-but-unused, decide: document as future work or remove
- [ ] Verify tier extension blocks are consistent between basic and full

**Deliverable:** Reference integrity report + keep/remove decision for archetypes and crew-patterns.

**Est:** 45 min.

### R4: Eval definition review (75 active)

**Goal:** Every eval measures a behavior we care about, uses the correct format, and has a defensible threshold.

- [ ] Categorize: activation (24), effectiveness, consolidation (18), other
- [ ] Flag evals using unsupported features (multi-turn `turns:`, `steering_override`) — convert or retire
- [ ] Flag evals for retired/merged skills that reference old skill names
- [ ] Verify threshold + delta_threshold match the eval's intent (variance-reduction vs lift)
- [ ] Check consolidation-* evals: post-consolidation, are they one-shot (done) or regression guards (keep)?
- [ ] Confirm judge criteria follow eval-criteria style guide

**Deliverable:** Per-eval verdict table; retire list; fix list.

**Est:** 4-5 subagent stages (file reading). ~1.5 hours.

### R5: Eval harness review

**Goal:** Harness correctness and maintainability after the isolation fix.

- [ ] Review run.sh end-to-end (534+ lines): flag dead code, error handling gaps
- [ ] Document supported definition schema (input vs turns, conditions, thresholds) — currently implicit
- [ ] Add multi-turn support OR document as unsupported (2 evals retired for this)
- [ ] Fix shared outputs/ dir collision (all evals in a run write to same outputs/ with task indexes — filenames don't include eval name)
- [ ] Add `--dry-run` validation mode that checks all definitions parse correctly
- [ ] Verify consensus judging handles judge failures gracefully

**Deliverable:** Fixed harness + `tools/evals/README.md` schema documentation.

**Est:** 2-3 hours direct work.

### R6: Tooling audit (generator, proofs, lint, recall, session-analyzer, okf-bundle)

**Goal:** Each tool works, is documented, and is still needed.

- [ ] generator: init.sh reviewed post-ADR-0008 (plugin code paths fully removed?)
- [ ] doctor.sh: does it check extensions? eval steering? cron?
- [ ] proofs: harness still runs? results current?
- [ ] lint: cross-link checks match current skill structure?
- [ ] recall CLI: spike/ dir cleanup, pyproject current?
- [ ] session-analyzer: still used? parse.py works against current session format?
- [ ] okf-bundle: still needed? documented?

**Deliverable:** Health report per tool; removal proposals for dead tooling.

**Est:** 1.5 hours, mix of direct + subagent.

### R7: Knowledge cleanup (docs/development, .memory)

**Goal:** Research history is navigable; stale specs are archived.

- [ ] docs/development: 25 files — add an index README categorizing by topic and status (current/historical)
- [ ] .memory/specs: 19 specs — mark each as ACTIVE / DONE / SUPERSEDED in frontmatter
- [ ] ADRs: verify 0008 status updated from Proposed → Accepted (it shipped)
- [ ] CONTEXT.md: current with post-consolidation terms (extensions, tiers, etc.)

**Deliverable:** Indexed docs, statused specs, updated ADR statuses.

**Est:** 1 hour.

### R8: Workspace hygiene (quick win)

**Goal:** Remove accumulated junk.

- [ ] Untracked files at repo root: `debounce.ts`, `debounce-final.ts`, `fixed-code.js` (eval artifacts leaked into repo root — delete)
- [ ] Untracked: `tools/evals/experiments/bedrock-model-family-comparison.yaml`, `tools/evals/harness/run-model-comparison.sh`, `tools/proofs/adapters/closecode.yaml` — decide: commit or delete
- [ ] README.md at repo root describes "Debounce Function" — completely wrong, needs rewrite for crew-research
- [ ] Check .gitignore covers eval workdir leakage

**Deliverable:** Clean git status; correct README.

**Est:** 30 min.

---

## Sequencing

```
R8 (hygiene, quick) → R1 (skills) → R2+R3 (context/compositions, small) 
→ R4 (eval definitions) → R5 (harness) → R6 (tooling) → R7 (knowledge)
```

R1 informs R4 (skill verdicts determine which evals stay relevant).
R5 should wait for the current eval run to finish (avoid changing harness mid-run).

## Current Status Snapshot (2026-07-16)

**ALL 8 TICKETS EXECUTED 2026-07-16.** Deliverables:

| Ticket | Outcome | Evidence |
|--------|---------|----------|
| R1 | 53 skills reviewed: 32 KEEP / 20 FIX / 1 MERGE / 0 RETIRE | `.scratch/skill-review/verdicts.md` + batch1-8.md |
| R2 | Deployment bug found+fixed: research-dispatch-mandate never deployed | `.scratch/r2-r3-audit.md`; commit e34b30f |
| R3 | All 21 compositions validate; archetypes/patterns confirmed in use | same |
| R4 | 75 evals: 47 KEEP / 7 FIX / 21 retired (→54 active) | `.scratch/eval-review/summary.md`; commit a374699 |
| R5 | Activation-leak + output-collision fixed; schema documented | `tools/evals/README.md`; commit bb29613 |
| R6 | generate.sh crash fixed; dead lint rewritten (catches frontmatter gaps); multi-agent-validation repaired+deployed | commit 0b1875a |
| R7 | ADR 0008 Accepted; 19 specs statused; glossary updated; docs indexed | commit d2b3c00 |
| R8 | 30 leaked eval files removed; README restored from HEAD | commits in range |

**Follow-up work: tracked as tickets in `.tickets/` (created 2026-07-16).**

| Ticket | Title | Blocked by |
|--------|-------|------------|
| 01 | Broken skill content repaired (P0 + one-liners) | ✅ done (e0fde71) |
| 02 | Cross-skill contradictions resolved | ✅ done (5cd6bb5 — troubleshooting-protocol merged into feedback-loop-debugging) |
| 03 | Over-budget skills fit 100-line limit | ✅ done (c54b412 — all 7 ≤100; grill+sdd evals re-passed post-trim) |
| 04 | Always-on steering slimmed 812→~450 lines | ✅ done — batch-5 total 387 lines; tool-installation demoted to project level; OS refs gated in init.sh; activation eval 0.90 accuracy |
| 05 | 7 flagged eval definitions run as designed | ✅ done (815fbe2 + validation runs: 4✅/1❌, the ❌ is genuine skill signal) |
| 06 | doctor.sh + catalog.sh report current reality | ✅ done (cd78f2c — tier reconciliation, recall staleness/cron, frontmatter lint, portable grep; catalog tags + --tier) |
| 07 | ~~Moved to recall repo~~ | ✅ done |
| 08 | Dead/broken tooling pruned or repaired | ✅ done — okf-bundle + prime hook deleted (decisions recorded), inspect-session exec bit fixed, run.sh skips null adapters, init.sh dead code removed |
| 09 | Clean post-review eval baseline | ✅ done (2026-07-18) — 26/35 judged (74.3%), 19/20 live activation; record: `docs/development/eval-baseline-2026-07-17.md` |
| 10 | Session logs reveal actual skill/tool usage | ✅ done — spike PASS (activation detectable); 595 sessions analyzed; report in docs/development/session-skill-usage-2026-07-17.md |
| 11 | Eval sessions cannot write outside their workdir | ✅ done (2b699cc — run-model-comparison.sh was the leaker, not run.sh) |
| 12 | Re-run full suite to validate threshold calibration | ✅ done — 25/35 pass (71.4%, target ≥30%), 0 regressions, 0 infra failures; notes in docs/eval-results-2026-07-17.md |
| 13 | architecture-deepening activates + rejects rubber-stamps | ✅ done (2026-07-18) — activation PASS (TPR 1.00, FPR 0), judged eval with-skill 5.00 / delta 4.00 |
| 14 | feedback-loop-debugging passes both effectiveness evals | ✅ done (2026-07-18) — root cause: fixture-task mismatch (tasks described nonexistent bugs), NOT merge dilution; per-task bug-injected fixtures + continuous-signal skill section; both PASS (4.44/4.44) |
| 15 | Eval harness resume capability | ✅ done (2026-07-18) — `--skip-completed <dir>` skips scored defs, appends into one dir; verified via dry-run truncate-resume (35/35 unique, meta preserved, idempotent) |
| 16 | Steering references stop defeating progressive loading | ✅ done (2026-07-18) — ADR 0009: refs deploy to skills tree, links rewritten absolute; always-on 90→0 managed lines; per-tool AGENTS.md manifests fix codex/agy shared-dir prune flap |
| 17 | Explore: script-file rule for bash invocations (windows steering) | ✅ done (2026-07-18) — Git Bash invocation section in project-conventions references/windows.md |
| 18 | Explore: concurrent-session ticket allocation guard | ✅ done (2026-07-18) — Creating Tickets section in frontier-work |
| 19 | recall skill activates on memory questions | ✅ done (2026-07-18) — h3 confirmed causally: recall-check steering owns the trigger space (skill correctly shadowed); def retired with rationale; steering-side field compliance is the measurement (t09 rec #1) |
| 20 | init.sh prunes only skills it deployed (manifest-based) | ✅ done (2026-07-18, bea4bfd) — incident: tier prune deleted 13 archwright skills |
| 21 | Deprecated-skills list drives cleanup of retired names | ✅ done (2026-07-18) — compositions/deprecated.yaml (16 names) wired into init prune, lint, doctor |
| 22 | mcp-partitioning skill — agent/MCP breakout guidance | ✅ done (2026-07-18, 34582a0) — kiro-scoped reference skill in full tier; eval-pass follow-up noted in ticket |
| 23 | recall-check steering gate raises field compliance above 21% | ✅ done 2026-07-25 — post-gate 7d: 43/122 (35%) vs 29% reference (+6pts); >50% target missed, recorded as finding + remediation candidates (session-skill-usage-2026-07-25.md) |
| 24 | Activation detection uses live output capture | ✅ done (2026-07-19) — output tees to .eval-output, Strategy 1 live (probe-verified); full run 19/20 defs, TPR .96/FPR .05 PASS; sole FAIL = git-protocol agent flake (verified genuine skill load, not detection) → ticket 27 |
| 25 | mcp-partitioning activation + effectiveness evals | ✅ done (2026-07-19) — activation TPR 1.00/FPR 0 (10/10); effectiveness with-skill 5.00/delta 2.56; suite now 36 judged + 21 activation defs |
| 26 | Eval baseline record reflects post-baseline fix batch | ✅ done (2026-07-19) — 28/35 judged (80.0%, was 26/35) @ 28ed513, 10.2h; known gaps 8→5 re-justified; record: `docs/development/eval-baseline-2026-07-19.md`; 2 new near-threshold FAILs → ticket 28 |
| 27 | activation-git-protocol negative tasks stop flaking at FPR gate | ✅ done 2026-07-22 — change-producing negatives replaced with read-only Q&A + comparability note; 2 consecutive solo runs TPR 1.00/FPR 0 PASS |
| 28 | Near-threshold judged failures triaged | ✅ done 2026-07-22 — agents-md GENUINE (trim-extraction skill fix, post-fix PASS 4.33); handoff-decaying + feedback-loop-tighten FLAKY (trials 3→5); a03798e regression ruled out; known gaps now 4 |
| 29 | Deferred eval protocol (adapter scoping, access probes, judge visibility, owed-run ledger) | ✅ done 2026-07-19 — SKIP rows, live-probe judge set, per-trial judge recording, id/adapter row keys + hash placeholders, ledger seeded. Discovery: codex judge leg was silently dead in ALL prior runs (untrusted temp dir) — local "consensus" was opus-only; fixed |
| 30 | image-* defs conform (ids, adapter scoping, deferred birth run) | ✅ done |
| 31 | crush deployment complete on this machine | ✅ done 2026-07-27 — deployed (idempotent, no cross-tool flap), doctor healthy, Bedrock sentinel probe PASSED (haiku-4.5 via sabiggin-isengard/us-west-2), docs + crush-bedrock.md reference; live probes NO LONGER deferred |
| 32 | Re-judge mode + cross-machine interchange | ✅ done 2026-07-25 — run.sh --judge-only (versioned rejudge files, recorded-commit criteria, verdict delta); interchange.sh export/import (join-key validation, tamper rejection, byte-identical round-trip) |
| 33 | Result identity hashes | ✅ done 2026-07-25 — identity.sh shared module, per-def execution-time hashes in rows, check-staleness.sh drift kinds, --changed-only; conformance: each component flips exactly its kind |
| 34 | Automated periodic session-history review | ✅ done 2026-07-27 — session_review.py folded into session-analyzer (detector fixes validated: spike FP sessions excluded, missed-correction c2befaf8 now caught + LLM-confirmed GENUINE); mise run session:review; digest-only, never creates tickets |
| 35 | Model cost/quality benchmarking (judges first: agreement vs 2026-07-19 consensus) | open — prefer cheaper models where quality holds; corp candidates incl. Bedrock Claude via crush (haiku-4.5) |
| 36 | Environment designation (CREW_ENV) + agy policy enforcement | ✅ done 2026-07-25 — init hard-refuse, doctor artifact flags (fires on planted manifest), eval adapter+judge legs and proof legs policy-blocked pre-probe with distinct reason; docs in AGENTS.md + user-setup-guide; corp deploy unchanged |
| 37 | Integrate archwright as a known tool (hydrated externally, recommended by relevant skills) | ✅ done 2026-07-19 — known-tools registry (`compositions/known-tools.yaml`) + doctor detection (hydrated/absent/broken-symlink) + catalog listing + 5 conditional seams (architecture-deepening, sdd, planning-cycles, grill, adr) + setup docs. Hydration = archwright's own symlink deploy (no tier extension — avoids double ownership). Known collision recorded: archwright's deploy copies its subagent-reliability fork over crew's (fix belongs in archwright) |
| 38–41 | ~~tkt CLI: explore, build, rollout~~ | ✅ done — moved to D:/code/tkt |
| 39 | doctor.sh checks WSL \$HOME instead of the Windows deploy home | ✅ done 2026-07-27 |
| 42 | Lint executable check false positive on Windows (core.filemode=false) | ✅ done |
| 43 | WSL bashrc should export WIN_USERNAME for deploy reliability | ✅ done |
| 44–47 | ~~tkt hardening, batch, wording~~ | ✅ done — moved to D:/code/tkt |
| 48 | guidance-sync reviews edits/deprecations, not just additions | ✅ done 2026-07-22 — P6 prune probe + net-delta metric + routing to owned mechanisms; 4-subagent research; related edits: session-analysis, AGENTS.md, project-audit, ticket 34 |
| 49–50 | ~~tkt close --note/--brief/--ac~~ | ✅ done — moved to D:/code/tkt |
| 51–61 | ~~recall workstream (force, sources, proofs, discovery, etc.)~~ | ✅ done — moved to recall repo |
| 62 | doctor: git-bash uv tools check | ✅ done |
| 63 | ~~recall pytest suite~~ | ✅ done — moved to recall repo |
| 64, 66 | ~~tkt sync-plan --fix (research + impl)~~ | ✅ done — moved to D:/code/tkt |
| 70 | Restore a second judge family on corp (codex fix or non-Anthropic Bedrock leg) | open (priority: high) — every corp run is a single Claude judge |
| 71 | Delta noise floor for single-family judge panels | open |
| 72 | Judge prompt/rubric into the identity scheme (template edits must read as drift) | open |
| 73 | Canonical judge panel + deviation reporting | open — blocked by 70 |
| 74 | Agreement-as-confidence audit; ICC + chance-corrected stats; measure our own γ̄ | open |

**Frontier (2026-07-29):** 35, 69, 70–74. Tickets 55, 68, and all tkt tickets (38–50, 64, 66, 67) moved to their respective repos (D:/code/tkt, recall repo). Ticket 69 now unblocked (67 done).

| Ticket | Lane | Ready? | Note |
|--------|------|--------|------|
| 35 | corp | in progress | phase 1 done; cheap-judge shadow study rejected per ADR 0010 |
| 70 | **corp** | yes, priority | restore a second judge family — blocks 73 |
| 71 | either | yes | delta noise floor for single-family panels |
| 72 | either | yes | judge prompt/rubric into the identity scheme |
| 73 | either | blocked by 70 | canonical panel + deviation reporting |
| 74 | either | yes | agreement-as-confidence audit |
| 69 | either | yes | eval harness architecture rebuild (exploration) |
| 30 | **personal** | env-blocked | image-* birth runs need GLM |

Deferred threads unchanged: t09 rec #2/#5 (~2026-08-17).

*Historical frontier snapshots removed — see git history for prior states.*


---

## Tool Extraction & Rebuild (2026-07-28)

**Goal:** Decompose crew-research from "many things in one repo" to focused tools that
each do one thing well. Rebuild CLI tools in Rust for single-binary distribution,
cross-platform reliability, and performance.

**Status (2026-07-29):** tkt and recall have been extracted to their own repos. Future
tickets for these tools live in their respective projects.

### Repos

| Tool | Repo | Status |
|------|------|--------|
| tkt | `D:/code/tkt` | Scaffolded, Rust rebuild in progress |
| recall | recall repo | Scaffolded, architecture spec done (`.memory/specs/recall-rust-architecture.md`) |
| eval harness | crew-research (ticket 69) | Exploration phase — may stay here or extract |

### Recommended Order (task graph)

```
67 (tkt → Rust) ✅ DONE    68 (recall → Rust) → recall repo
  │ simplest,                │ highest value,
  │ proves pattern           │ complex (ML)
  │                          │
  └──────┬───────────────────┘
         │ lessons learned
         ▼
69 (eval harness → compiled) ← still in crew-research
   │ may stay in crew-research
   │ but architecture rebuild
```

### What stays in crew-research after extraction

- `atomics/` — skill content (the product)
- `compositions/` — tier manifests
- `tools/generator/` — deploy tooling (bash, reads local files)
- `tools/evals/` — eval definitions + harness (ticket 69 decides architecture)
- `tools/proofs/` — platform assumption tests
- `tools/lint/` — cross-link validation
- `.memory/`, `.kiro/`, `docs/` — project knowledge

### What graduated to separate repos

- `tools/tkt/` → `D:/code/tkt` (Rust binary, crates.io/cargo-binstall)
- `tools/recall/` → recall repo (Rust binary, single-file distribution)
