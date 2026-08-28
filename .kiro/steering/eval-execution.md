# Eval Execution

When running evals (`mise run eval`, `mise run eval:one`, or the harness directly):

## Always use background execution

Evals take 5-15 minutes each. A full suite (100+) takes hours. Never run inline.
(Exception: `--dry-run` finishes in seconds — inline is fine.)

```bash
setsid nohup bash tools/evals/harness/run.sh [args] > /tmp/full-eval-run.log 2>&1 < /dev/null &
echo "PID: $!"
```

**`setsid` is mandatory, not optional** — plain nohup dies when the launching kiro session ends (the sandbox kills the process group; incident: 2026-07-17 t12 run killed at 11/35).

## Observe with sleep cycles

**Never use the launcher PID for liveness.** `setsid` forks — `$!` is the wrapper, which exits immediately; `kill -0 $!` reports DEAD while the run is healthy (2026-07-19 incident: a healthy 10-hour judged run was misdiagnosed as a failed launch at 120s and nearly double-launched; artifact forensics rescued it). Liveness = the run's own artifacts:

```bash
sleep N; wc -c /tmp/full-eval-run.log      # growing log = alive
ls -dt tools/evals/results/*/ | head -1     # results dir exists + outputs/ mtimes advance
ps aux | grep -c "[r]un.sh"                 # bracket trick — process check without self-match
tr -d '\000' < /tmp/full-eval-run.log | grep -E "✅|❌"
```

- First check: `sleep 60` (confirm the log exists and grows)
- Subsequent checks: `sleep 300` or longer based on pace
- Filter null bytes: the harness output contains terminal control chars
- A stale log ≠ dead: judged trials can be silent for many minutes — confirm with the process check before concluding anything

## Estimate completion

- Each judged eval ≈ 6-67 min, median ~17 min (12 sessions: 3 trials × 2 conditions × 2 tasks, plus consensus judging — the live judge set is machine-dependent and recorded in `meta.json` → `judges.live/excluded`; corp machines typically judge kiro-only)
- Full judged suite (35 evals) ≈ 8-10 hours
- Single activation def (10 tasks) ≈ 12 min

## Hard Rules (incidents behind each)

- **NEVER edit `run.sh` (or any script) while a run is executing it.** Bash re-reads the file mid-execution — the 2026-07-15 overnight run wedged at 102/105 with a syntax error after a live edit. Queue harness changes until the run finishes.
- **Every agent-invoking script MUST run the agent inside a temp workdir** (`mktemp -d` + subshell `cd`). `run-model-comparison.sh` ran closecode in the repo root on 2026-07-15 and leaked ~30 generated files (debounce.ts etc.) into the repo, overwriting README.md. Judges score only — invoke them without `-a` and inside a temp dir.
- **After any run, check `git status`** — a dirty repo means a containment regression.

## Headless kiro-cli invocation (stream-json — tickets 124/125)

When invoking `kiro-cli chat` headlessly to capture structured output:

- **`--agent-engine v2 -a` is MANDATORY for headless.** v1 rejects `--output-format stream-json` ("not supported on the v1 engine"). **v3 CANNOT run headless at all** — it forwards `session/new` to the TUI and HANGS with no non-TUI path (2026-08-28: `--agent-engine v3` headless hung 3× before diagnosis; kiro.dev v3 "Known Gaps" confirms "legacy non-TUI mode does not support the v3 engine"). v3 also rejects `-a` (capability `permissions.yaml` model). Pin v2 for anything scripted/non-interactive; bound the call (see windows.md Start-Job wrapper) so a v3/hang can't wedge the session.
- **Separate stdout from stderr**: `> events.jsonl 2>err.log`. NEVER `2>&1` — the JSON stream is stdout-only; merging stderr corrupts it.
- **Validate by output content, never exit code** — kiro-cli, opencode, AND codex all exit 0 on failure / nonzero on would-be success. Confirm a real terminal event (`runFinished`/`step_finish reason:"stop"`) + non-empty final text.
- **Run the invocation ALONE, inspect output in a SEPARATE call.** A `kiro-cli chat` stream call chained with trailing `Get-Content`/`jq`/`Write-Host` in one PowerShell invocation blocks the whole call and wastes it (observed 2026-08-27: test-4 cancelled 3× from chaining). Invoke, wait, then read the file in the next command.
- Each invocation is its own session UUID — safe to run alongside an active interactive session; it never touches the live session's log.

```bash
# Invoke (one call)
kiro-cli chat --agent-engine v2 -a --output-format stream-json "PROMPT" > events.jsonl 2>err.log
# Inspect (separate call)
jq -rn 'last(inputs | select(.type=="runFinished") | .data.finalText) // ""' events.jsonl
```

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
