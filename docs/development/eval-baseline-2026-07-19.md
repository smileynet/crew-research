# Eval Baseline — 2026-07-19 (ticket 26)

**Run:** commit `28ed513` (skills/steering state), started 2026-07-19 00:29 UTC, completed 2026-07-19 10:41 UTC (10.2h).
**Results:** judged `tools/evals/results/2026-07-19T00-29-50Z/`, activation `results/activation-2026-07-18T21-56-19Z/` (+ git-protocol solo confirm `activation-2026-07-19T00-16-48Z/`). Log: `/tmp/judged-run-t26.log` (ephemeral).

Supersedes `eval-baseline-2026-07-17.md` (26/35 @ `24d9691`). This run incorporates the post-baseline fix batch: tickets 13 (architecture-deepening), 14 (feedback-loop fixtures), 16 (ADR 0009 steering refs), 19 (activation-recall retired), 22–24.

## Phase 1 — Judged Effectiveness: 28/35 pass (80.0%)

Prior: 2026-07-17 baseline 26/35 (74.3%); t12 25/35 (71.4%).

### Delta vs 2026-07-17 baseline

**Flipped to PASS (4):**
- architecture-deepening-rubber-stamp 1.00 → 5.00/delta 4.00 (ticket 13 fix confirmed at suite level)
- feedback-loop-effectiveness 2.66 → 4.44/delta 2.67 (ticket 14 fixtures confirmed)
- small-model-code-edit 3.11 → 3.66 (known near-miss cleared; one 0-score trial still present — watch)
- steering-pointer-effectiveness 3.83 → 4.30 (5-trial change validated the "flaky" triage)

**Flipped to FAIL (2, both NEW → ticket 28):**
- agents-md-authoring-effectiveness 4.16 → 3.83 (thr 4). Delta still positive (1.0); task 1 with-skill flat 3.0 across trials; stddev 0.89 unchanged. Near-threshold variance suspected.
- handoff-decaying-resolution 5.00/delta 1.67 → 4.50/delta 0.67 (delta thr 0.75). First post-merge measurement of the a03798e handoff content (old baseline scored it pre-merge — recorded caveat). Baseline condition rose 3.33→3.83, compressing delta. Flake vs content regression undetermined.

### Failures (7) and classification

| Definition | Score | Classification |
|-----------|-------|----------------|
| type-error-diagnosis-reads-before-fix | 2.44 (thr 3.5) | Known gap (stable across 3 runs) |
| prototype-branch-picking-effectiveness | 3.66 (thr 4) | Known gap (stable: 3.77 → 3.66) |
| code-review-security-vulnerability-detection | delta 0.08 (thr 0.75) | Known gap — `known_gap` frontmatter (cross-model) |
| cross-tool-planning-with-skills | delta 0 (thr 0.3) | Known gap — `known_gap` frontmatter (cross-model) |
| feedback-loop-tighten-effectiveness | 3.77 (thr 4) | Flaky at threshold — 3.88 FAIL → 4.44 PASS (ticket 14 runs) → 3.77 FAIL, delta healthy (1.33–1.89 across runs); task 2 weak (2.66). Folded into ticket 28 triage |
| agents-md-authoring-effectiveness | 3.83 (thr 4) | NEW → ticket 28 |
| handoff-decaying-resolution | delta 0.67 (thr 0.75) | NEW → ticket 28 |

**Known-gap re-justification (was 8, now 5):** small-model-code-edit cleared (passed); steering-pointer cleared (5-trial fix); architecture-deepening + feedback-loop-effectiveness fixed by tickets. Remaining: the 4 stable rows above + feedback-loop-tighten (downgraded from "fixed" to flaky-at-threshold pending ticket 28).

### Ticket 28 dispositions (amended 2026-07-22)

Solo re-runs at unchanged content (2× each; judge caveat: kiro-only — codex/crush probes failed, agy absent on corp; 07-19 run was multi-judge):

| Def | Re-run results | Classification | Remedy |
|-----|---------------|----------------|--------|
| agents-md-authoring-effectiveness | FAIL 3.83 / FAIL 3.66 — trim task flat 3 in 9 straight trials across both judge configs | GENUINE | Skill content fix: trim step 2 now requires WRITING extraction files ("a link to a file that doesn't exist is deletion, not extraction"). Post-fix verify: PASS 4.33/delta 1.33, trim task [4,5,4] (run 2026-07-22T23-28-34Z) |
| handoff-decaying-resolution | PASS delta 0.83 / PASS delta 0.83 (thr 0.75) | FLAKY at delta gate (0.67/0.83/0.83) | trials 3→5. a03798e content regression RULED OUT: 0/6 with-skill outputs contained the Recommended Updates nudge — its skip-condition works on simple fixture sessions; 07-19 delta compression came from baseline rise (judge-set boundary 69547a8 suspected) |
| feedback-loop-tighten-effectiveness | PASS 4.44 / PASS 4.33 (thr 4) | FLAKY at score threshold (3.88/4.44/3.77/4.44/4.33) | trials 3→5; leaves the known-gap set |

Known-gap set is now the 4 stable rows only (type-error-diagnosis, prototype-branch-picking, code-review-security, cross-tool-planning-with-skills).

## Phase 2 — Activation: 19/20 live defs pass

Run `activation-2026-07-18T21-56-19Z` (200 tasks, post-ticket-24 detection: Strategy 1 live). Overall TPR .96, FPR .05, verdict PASS.

- **git-protocol FAIL (FPR 0.4):** verified agent-behavior flake, not detection regression — the FP conversation contains a genuine `skills/git-protocol/SKILL.md` read (session-DB check); one FP task is stable across 3 runs, the other flakes. → **ticket 27**
- New def activation-architecture-deepening: TPR 1.00, FPR 0 (ticket 13).
- activation-recall retired (ticket 19) — excluded from denominator.

## Baseline invariants for next run

- **Amendment 2026-07-19 (ticket 25):** suite grew by 2 defs, both passing at birth — `mcp-partitioning-effectiveness` (with-skill 5.00 / delta 2.56, run `2026-07-19T13-32-32Z`) and `activation-mcp-partitioning` (TPR 1.00 / FPR 0, run `activation-2026-07-19T13-13-30Z`). Next full run expects ≥29/36 judged, 20/21 activation (21/21 after ticket 27).
- **Amendment 2026-07-19 (ticket 29) — judge set was opus-ONLY, not opus+codex:** the codex judge leg silently died in every prior run (codex exec refuses untrusted temp dirs without `--skip-git-repo-check`; stderr was discarded — zero codex sessions exist for any judged-run window). All "consensus" scores in this baseline (and all prior local runs) are single-judge opus-4.6 scores. Fixed in ticket 29 (flag added + access probes + judge recording); the next full run will be a genuine ≥2-judge consensus, so expect some score movement attributable to the judge-set change, not skill changes. Post-29, three image-* defs SKIP under kiro-cli (adapter-scoped to crush) — future full runs report 36 scored + 3 skipped.
- Judged: expect ≥28/35. Known-gap set (5): type-error-diagnosis, prototype-branch-picking, code-review-security, cross-tool-planning-with-skills, feedback-loop-tighten (pending ticket 28). agents-md + handoff-decaying pending ticket 28 triage — if confirmed flaky, they join steering-pointer's precedent (trials increase), not the gap set.
- Any NEW failure outside these 7 names is a regression.
- Activation: expect 19/20 until ticket 27 lands, then 20/20.
- Suite composition changes must preserve `id:` fields; feedback-loop history pre-2026-07-18 non-comparable (ticket 14 fixture change).
