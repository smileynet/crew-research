# Eval Execution

When running evals (`mise run eval`, `mise run eval:one`, or the harness directly):

## Always use background execution

Evals take 5-15 minutes each. A full suite (100+) takes hours. Never run inline.

```bash
setsid nohup bash tools/evals/harness/run.sh [args] > /tmp/full-eval-run.log 2>&1 < /dev/null &
echo "PID: $!"
```

**`setsid` is mandatory, not optional** — plain nohup dies when the launching kiro session ends (the sandbox kills the process group; incident: 2026-07-17 t12 run killed at 11/35).

## Observe with sleep cycles

```bash
sleep N && kill -0 $PID 2>/dev/null && echo "RUNNING" || echo "DONE"
tr -d '\000' < /tmp/full-eval-run.log | grep -E "✅|❌"
```

- First check: `sleep 60` (confirm it started)
- Subsequent checks: `sleep 300` or longer based on pace
- Filter null bytes: the harness output contains terminal control chars

## Estimate completion

- Each judged eval ≈ 6-67 min, median ~17 min (12 sessions: 3 trials × 2 conditions × 2 tasks, plus 4-model consensus judging)
- Full judged suite (35 evals) ≈ 8-10 hours
- Single activation def (10 tasks) ≈ 12 min

## Hard Rules (incidents behind each)

- **NEVER edit `run.sh` (or any script) while a run is executing it.** Bash re-reads the file mid-execution — the 2026-07-15 overnight run wedged at 102/105 with a syntax error after a live edit. Queue harness changes until the run finishes.
- **Every agent-invoking script MUST run the agent inside a temp workdir** (`mktemp -d` + subshell `cd`). `run-model-comparison.sh` ran closecode in the repo root on 2026-07-15 and leaked ~30 generated files (debounce.ts etc.) into the repo, overwriting README.md. Judges score only — invoke them without `-a` and inside a temp dir.
- **After any run, check `git status`** — a dirty repo means a containment regression.

## When done

```bash
cat tools/evals/results/<timestamp>/scores.jsonl | jq -s '.' 
```

Report: total pass/fail, any new failures vs previous run, notable delta changes.

## If a run dies mid-suite

Resume into the SAME results dir — never hand-script per-definition loops:

```bash
setsid nohup bash tools/evals/harness/run.sh --all --skip-completed tools/evals/results/<dead-run-dir> > /tmp/resume.log 2>&1 < /dev/null &
```

Already-scored definitions are skipped; the dir ends with one complete scores.jsonl.
