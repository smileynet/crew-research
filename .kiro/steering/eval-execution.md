# Eval Execution

When running evals (`mise run eval`, `mise run eval:one`, or the harness directly):

## Always use background execution

Evals take 5-15 minutes each. A full suite (100+) takes hours. Never run inline.

```bash
nohup bash tools/evals/harness/run.sh [args] > /tmp/full-eval-run.log 2>&1 &
echo "PID: $!"
```

## Observe with sleep cycles

```bash
sleep N && kill -0 $PID 2>/dev/null && echo "RUNNING" || echo "DONE"
tr -d '\000' < /tmp/full-eval-run.log | grep -E "✅|❌"
```

- First check: `sleep 60` (confirm it started)
- Subsequent checks: `sleep 300` or longer based on pace
- Filter null bytes: the harness output contains terminal control chars

## Estimate completion

- Each eval ≈ 8 min (6 sessions: 3 trials × 2 conditions)
- Full suite (105 evals) ≈ 5-6 hours
- Single eval ≈ 8 min

## When done

```bash
cat tools/evals/results/<timestamp>/scores.jsonl | jq -s '.' 
```

Report: total pass/fail, any new failures vs previous run, notable delta changes.
