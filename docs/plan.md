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
| 07 | Installed recall CLI matches source and docs | ✅ done — 0.2.0 reinstalled from source; import round-trip verified; all install docs point at ./tools/recall; spike findings promoted |
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
| 23 | recall-check steering gate raises field compliance above 21% | 🕐 in measurement window (2026-07-18) — gate deployed all 3 tools; measure ≥2026-07-25 (`mise run session:skills 7`); pre-fix 7d ref 78/271 (29%) |
| 24 | Activation detection uses live output capture | ✅ done (2026-07-19) — output tees to .eval-output, Strategy 1 live (probe-verified); full run 19/20 defs, TPR .96/FPR .05 PASS; sole FAIL = git-protocol agent flake (verified genuine skill load, not detection) → ticket 27 |
| 25 | mcp-partitioning activation + effectiveness evals | ✅ done (2026-07-19) — activation TPR 1.00/FPR 0 (10/10); effectiveness with-skill 5.00/delta 2.56; suite now 36 judged + 21 activation defs |
| 26 | Eval baseline record reflects post-baseline fix batch | ✅ done (2026-07-19) — 28/35 judged (80.0%, was 26/35) @ 28ed513, 10.2h; known gaps 8→5 re-justified; record: `docs/development/eval-baseline-2026-07-19.md`; 2 new near-threshold FAILs → ticket 28 |
| 27 | activation-git-protocol negative tasks stop flaking at FPR gate | open — found in ticket 24's no-regression run; 2 negative tasks naturally lead to commit territory |
| 28 | Near-threshold judged failures triaged (agents-md, handoff-decaying, fl-tighten) | open — found in ticket 26's baseline run; flaky-vs-genuine per steering-pointer precedent |
| 29 | Deferred eval protocol (adapter scoping, access probes, judge visibility, owed-run ledger) | open — this machine lacks crush/agy access; consensus judging silently degraded to ~2 judges (unrecorded) |
| 30 | image-* defs conform (ids, adapter scoping, deferred birth run) | open, blocked by 29 — upstream 5a23e45 defs lack immutable ids and would blind-run under kiro-cli |
| 31 | crush deployment completeness (deploy + idempotency + docs; probes deferred) | open — capability landed upstream but not deployed here; docs have zero crush coverage |
| 32 | Results support async completion: re-judge mode + interchange | open, blocked by 29 — outputs already retained (feasible); needs row keys, --judge-only, export/import |
| 33 | Result identity hashes (skill/def/env drift detection + --changed-only) | open, blocked by 29 — makes staleness computed not remembered (a03798e + ticket-14 precedents) |
| 34 | Explore: automated session-history self-improvement review | open — /guidance-sync's archived-sessions counterpart; spike-first; global findings route through crew-research |

**Frontier (2026-07-19):** 27, 28, 29, 31, 34 (30 + 32 + 33 blocked by 29; 23 waiting on its ≥1-week measurement window, reopens ~2026-07-25). Remaining non-ticketed thread: t09 rec #2/#5 (planning-cycles overlap, multi-agent-validation re-measure) — both deliberately deferred to ~2026-08-17.

**Ticket ID collision (2026-07-17):** upstream (Windows session) allocated tickets 12+13 concurrently with local 13-16 — renumbered upstream to 17+18 on merge (a03798e). This is the second real-world occurrence of the race ticket 18 describes; cite it as evidence when working 18.

**Baseline caveat (t09):** merge a03798e landed `atomics/skills/handoff/SKILL.md` changes mid-run at 19/35 judged evals. `handoff-decaying-resolution` completed pre-merge (✅ 5.00, clean vs 24d9691); phase-2 `activation-handoff` will measure post-merge content. Do NOT redeploy global steering/skills (`mise run init --global`) until the run prints BASELINE RUN COMPLETE.

**Frontier (2026-07-16 19:20):** 02, 04, 05, 06, 07, 08, 10, 11. Ticket 12 (was numbered 01, renamed to fix ID collision; spec eval-improvements-2026-07-16) gained blockers 05+11 — running the suite with 6 known-broken definitions and an uncontained workdir leak would waste a 5-6h run. If 01-04 land before 12 runs, consider merging 12 into 09 (one clean run satisfies both).

**Active order:** 05 → 11 → 12 (background) with 02 → 03 in foreground; 04, 06, 07, 08, 10 parallelizable; 09 last.

**Open hygiene item (carried from R8):** untracked files still undecided — `docs/findings/`, `tools/evals/experiments/bedrock-model-family-comparison.yaml`, `tools/evals/harness/run-model-comparison.sh`, `tools/proofs/adapters/closecode.yaml`. Commit or delete during ticket 08.

**Overnight full-suite run (2026-07-15→16):** 102/105 completed, 32✅/70❌ — failure count dominated by since-retired evals and pre-calibration activation thresholds. Run wedged at 102 after run.sh was edited mid-execution (lesson recorded: never edit a script bash is executing); terminated, scores preserved in `/tmp/full-eval-run.log` and `tools/evals/results/2026-07-15T12-56-23Z/`.
