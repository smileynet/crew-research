---
name: eval-harness
description: "Run and interpret crew-research evals — run.sh flags, scores.jsonl fields, activation TPR/FPR verdicts, resuming interrupted runs. Use when running evals, reading eval results, diagnosing a failing definition, or resuming a dead run. Trigger: run the evals, eval results, scores.jsonl, activation test, TPR, delta threshold, resume the run, skip-completed, known gap."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Eval Harness

Run discipline (backgrounding, setsid, observation cycles) lives in `.kiro/steering/eval-execution.md` — always loaded. This skill covers invocation and output interpretation.

## Judged evals — `tools/evals/harness/run.sh`

```bash
bash run.sh --definition <name>              # one def
bash run.sh --all                            # full suite (~8-10h, 39 defs)
bash run.sh --all --dry-run                  # fast, no agents/judges (plumbing test)
bash run.sh --all --skip-completed <dir>     # RESUME: skip defs already in <dir>/scores.jsonl, append into it
bash run.sh --definition <name> --trials 5   # more trials (default 3)
bash run.sh --adapter crush --definition <name>   # run under another tool (kiro-cli default); --model overrides the agent model
```

- Results land in `tools/evals/results/<timestamp>/` (resume mode: the given dir; original meta.json preserved, resume metadata in `meta-resume-<ts>.json`).
- Defs support per-task `fixture:` overriding the def-level fixture (real injected bugs — see `fixtures/defu-null-bug.yaml`).
- Definition schema and criteria style: `tools/evals/README.md` + the `eval-criteria` skill.
- **Adapter scoping + access probes (ticket 29):** defs with `adapters: [x]` SKIP under other adapters; agent and judges are access-probed with a real prompt (`EVAL_PROBE_TIMEOUT`, default 30s) — PATH ≠ access. SKIP rows carry a reason, don't count as pass/fail/completed, and owe a run in `docs/development/deferred-runs.md`.
- **Judge participation is recorded** per trial (`task_scores[].judges`) and per run (`meta.json` → `judges.live/excluded`). Pre-2026-07-19 results have NO judge recording and were opus-only on this machine (crush never scored; codex silently died in untrusted temp dirs — fixed) — don't compare consensus scores across that boundary. **Corp machines typically judge kiro-only** (codex/crush access probes fail, agy absent — observed 2026-07-22, ticket 28): check `judges.live` before comparing scores across machines or against multi-judge baselines.

## Reading scores.jsonl (one JSON line per definition)

| Field | Meaning |
|-------|---------|
| `id` / `adapter` | immutable def id (longitudinal/cross-adapter key) + the adapter that ran |
| `status` | PASS/FAIL — with-skill avg vs `threshold`, delta vs `delta_threshold`; SKIP = not run (see `reason`) |
| `judges` | union of judges that scored this def; per-trial sets in `task_scores[].judges` |
| `with_score` / `without_score` / `delta` | condition averages; delta is the skill's contribution |
| `task_scores[]` | per-task, per-condition `avg` + raw trial `scores` — **start here when a def fails**. `task` indices are 0-based (task 1 = the SECOND task in the def) |
| `activation_rate` | share of with-skill trials where the skill actually loaded |
| `skill_hash` / `def_hash` / `env_id` | null placeholders until ticket 33 lands identity hashes |
| trial score `0` | usually a timeout (output cut mid-stream), not a judged zero — read the output file |

Trial outputs: `outputs/{def}-{condition}-task{N}-trial{M}.txt`. A def failing with high baseline = task may be doable without the skill; failing with 0-score trials = check for timeout spirals (possibly an impossible task — verify the fixture actually contains the described bug).

`known_gap:` frontmatter marks accepted cross-model failures — those FAILs are expected; only NEW failures outside the known set are regressions (baseline record: `docs/development/eval-baseline-*.md`).

## Activation evals — `tools/evals/harness/run-activation.sh`

```bash
bash run-activation.sh --definition activation-<skill>
bash run-activation.sh --all        # excludes definitions/retired/
```

- Verdict gates: TPR ≥ 0.5 AND FPR ≤ 0.2 (env-overridable: `ACTIVATION_TPR_GATE`/`ACTIVATION_FPR_GATE`). Unforced activation baseline is ~40-50%, so TPR 1.0 is exceptional, 0.6 is fine.
- The run summary is aggregate-only. **Per-def verdicts** (needed for no-regression comparisons) come from activation.jsonl:

```bash
python3 -c "
import json
from collections import defaultdict
d = defaultdict(lambda: {'TP':0,'FP':0,'TN':0,'FN':0})
for line in open('<run-dir>/activation.jsonl'):
    r = json.loads(line); d[r['skill']][r['result']] += 1
for s, c in sorted(d.items()):
    tpr = c['TP']/(c['TP']+c['FN']) if c['TP']+c['FN'] else 1.0
    fpr = c['FP']/(c['FP']+c['TN']) if c['FP']+c['TN'] else 0.0
    print(f\"{s:30s} TPR={tpr:.2f} FPR={fpr:.2f} {'PASS' if tpr>=0.5 and fpr<=0.2 else 'FAIL'}\")
"
```

(Snippet, not a script, by decision 2026-07-19: the jsonl schema changes when ticket 29 lands row keys — promote to `tools/` only if the need survives that change.)
- Output: per-task TP/FN/TN/FP lines + `summary.json`. FN on a positive task = description lacks that task's vocabulary; FP = description too broad.
- Detection greps the session DB for the skill's H1 (output-based Strategy 1 is currently dead code — ticket 24). **A skill shadowed by always-on steering covering the same triggers will score 0 TPR while behaving correctly** — retire the def instead of fighting it (precedent: activation-recall, ticket 19).

## Retiring a definition

Move to `definitions/retired/` with a `# RETIRED <date>: <why>` comment block after the `id:` line. Never delete — `id:` is the longitudinal key. Retired defs are excluded from `--all` automatically.
