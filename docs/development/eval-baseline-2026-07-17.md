# Eval Baseline — 2026-07-17 (ticket 09)

**Run:** commit `24d9691` (skills/steering state), started 2026-07-17 10:41 UTC, completed 2026-07-18 02:00 UTC (15.3h).
**Results:** judged `tools/evals/results/2026-07-17T10-41-09Z/`, activation `results/activation-2026-07-17T22-18-29Z/`. Log: `/tmp/baseline-t09.log` (ephemeral).

This is the post-review-arc baseline (tickets 01–08, 10–12 applied). Future runs compare against these numbers using the immutable `id:` field added 2026-07-18.

## Phase 1 — Judged Effectiveness: 26/35 pass (74.3%)

Prior runs: 2026-07-15 pre-review 32/105 (old suite, 12 comparable names); t12 rerun 25/35 (71.4%).

### Failures (9) and triage

| Definition | Score | Classification |
|-----------|-------|----------------|
| architecture-deepening-rubber-stamp | 1.00 (thr 4) | Genuine gap — 0/6 activation across 3 runs → **ticket 13** |
| feedback-loop-effectiveness | 2.66 (thr 3.5) | Genuine gap, pre-dates ticket-02 merge → **ticket 14** |
| feedback-loop-tighten-effectiveness | 3.88 (thr 4) | Genuine gap → **ticket 14** |
| type-error-diagnosis-reads-before-fix | 1.77 (thr 3.5) | Genuine gap (known) |
| prototype-branch-picking-effectiveness | 3.77 (thr 4) | Genuine gap (known) |
| code-review-security-vulnerability-detection | delta 0 | Cross-model — `known_gap` field added |
| cross-tool-planning-with-skills | delta -0.33 | Cross-model — `known_gap` field added |
| small-model-code-edit | 3.11 (thr 3.5) | Small-model near-miss (known) |
| steering-pointer-effectiveness | 3.83 (thr 4) | **Flaky, not regression** — task 1 is a restraint control with baseline at ceiling; one violation trial swings 0.67. trials 3→5 applied 2026-07-18 |

### Delta vs t12 (25→26)

- Flipped to PASS: grill-question-dithering-codex (3.50→5.00), small-model-instruction-following
- Flipped to FAIL: steering-pointer-effectiveness (4.50→3.83, triaged flaky)
- Zero new genuine regressions.

## Phase 2 — Activation: 19/20 live defs pass

Gates: TPR ≥ 0.5, FPR ≤ 0.2. Zero false-positive failures; fiction-craft and git-protocol at FPR 0.2 (exactly at gate).

- **Harness artifact discovered:** recursive `find` also ran 14 retired defs — 11/12 apparent FAILs and the run's summary `Verdict: FAIL` were artifacts. Fixed 2026-07-18 (`-not -path "*/retired/*"`). Live-def verdict computed post-hoc from `activation.jsonl`.
- **Genuine failure: `activation-recall` TPR 0/5.** Description flatten ruled out as fix (re-verified 0/5) → **ticket 19** with three hypotheses (file-answerable task phrasing, question-form matching, recall-check steering owns the trigger space).

## Caveats

1. **Mid-run merge:** commit `a03798e` landed `atomics/skills/handoff/SKILL.md` changes at 19/35 judged. `handoff-decaying-resolution` completed pre-merge (5.00); `activation-handoff` measured post-merge content (TP 5/5, FP 0/5 — passed either way).
2. Retired defs polluted the activation run (see above) — excluded from all tallies here.

## Recommendations (from session review 2026-07-17, disposition 2026-07-18)

1. **recall-check steering needs a stronger mechanism** — field compliance 21% (60/284 history-question sessions; `session-skill-usage-2026-07-17.md`). Now coupled to **ticket 19** (hypothesis 3 decides skill vs steering ownership).
2. **planning-cycles overlap review** — 1 field activation/30d while sdd (6) and grill-with-docs (6) win its trigger space. Revisit at next tier revision; don't act on eval data alone (passing niche: destination-first framing).
3. **Known cross-model gaps** — ✅ done: `known_gap:` frontmatter on 3 defs + README schema docs.
4. **Stable definition IDs** — ✅ done: immutable `id:` on all 111 definitions (live + retired).
5. **multi-agent-validation re-measure** — only never-activated deployed skill, but frontmatter/body were broken until 2026-07-17. Re-run `mise run session:skills` ~2026-08-17 before any retirement judgment.

## Baseline invariants for next run

- Judged: expect ≥26/35 with the 8 known-gap failures stable; any NEW failure outside that set is a regression
- Activation: expect 20/20 after ticket 19 (or 19/19 if activation-recall is retired)
- Suite composition changes must preserve `id:` fields
