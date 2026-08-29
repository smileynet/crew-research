# tools/review

Multi-model dispatch-review support. Fan-out helper for running the same review
through several opencode model reviewers; fan-in stays agent-driven (main context).

## matrix.sh — fan-out helper

Launches one `opencode run --auto -m <model> --format json` reviewer per model,
each capturing to a per-model artifact under `.scratch/review/<RUN_ID>/`, and
reconciles produced-vs-expected against a manifest. **Fan-out only** — it does
not dedup, tier, or create tickets.

```bash
bash tools/review/matrix.sh --run-id <uuid> --target <sha> [--models a,b,c] [--dir <repo>] [--dry-run]
```

- `--run-id`   correlation id (required; shared across the matrix)
- `--target`   commit sha under review (required)
- `--models`   comma-separated override; default = adapter `dispatch_review.models`
- `--dir`      repo to review in (default: this repo root)
- `--dry-run`  print invocations, write manifest/summary, no opencode calls

## Health preflight (`--health`)

Readiness-probe every reviewer model BEFORE spending tokens on a real run. Sends a
trivial "Reply with exactly: OK" to each model and validates the OUTPUT (readiness,
not just auth/liveness) — catches the "authenticated but model unavailable" case
(the codex-131 failure mode) that a presence check misses.

```bash
bash tools/review/matrix.sh --health [--models a,b,c]
```

- No `--target`/`--run-id` needed (defaults a timestamp run-id).
- Per-model ✅/❌ table + `.scratch/review/<run-id>/health-summary.json`
  `{status, checked, unhealthy, models:[{model,healthy,reason}]}`.
- Failure reason classified best-effort: `model_unavailable | auth | quota |
  server_error | empty_or_timeout | indeterminate` (from the JSONL error event +
  stderr, per `coding-plan-limits` vocabulary).
- Exit 0 = all healthy, 1 = ≥1 down, 2 = usage/env error.
- Run under Git Bash, bounded (opencode can hang). One probe per model, sequential.

**Exit codes:** 0 = all expected reviewers produced a valid result; 1 = coverage
gap (≥1 indeterminate/missing); 2 = usage/environment error.

**Outputs** (in `.scratch/review/<RUN_ID>/`):
- `manifest.json`      — expected reviewer slugs (written before dispatch)
- `<slug>.jsonl`       — raw opencode JSONL per reviewer
- `<slug>.md`          — extracted final text (findings + REVIEW_RESULT line)
- `matrix-summary.json`— `{status, run_id, target, expected, produced, missing[], reviewers[]}`
## Isolation & safety

- Each run creates a throwaway `git worktree` at `--target` (shares the object
  store, cheap) and runs the reviewer there — NOT the live working tree. Any
  accidental write is contained; the worktree is removed on exit. `--target` must
  be a valid commit or the run exits 2.
- The reviewer prompt is **findings-only**: it forbids editing files and forbids
  creating/committing/pushing any ticket. Reviewers emit findings inline (JSONL)
  + one `REVIEW_RESULT` line; the PARENT fan-in creates the single aggregate
  ticket (single writer → no ID race).
- `events.jsonl` may contain FULL file contents (a reviewer's `read` tool output
  is captured verbatim) — treat it as sensitive as the reviewed repo. Only the
  extracted `REVIEW_RESULT`/findings text (`<slug>.md`) is surfaced; raw JSONL is
  not logged or shipped.

## Validity rule (why exit code isn't trusted)

opencode's exit code is unreliable (can exit 0 on failure, hang, or surface 429
silently). A reviewer result counts as valid ONLY if its JSONL has a
`step_finish` with `reason:"stop"` (the LAST one — a tool-using run has an earlier
`reason:"tool-calls"` step_finish) AND non-empty assistant text AND a
`REVIEW_RESULT` line (extracted fence-tolerant, last-match). Anything else →
`indeterminate` → coverage gap (never "clean"). Quota-exhausted reviewers (see
`coding-plan-limits`) land here as dropped reviewers, degrading the run without
failing it.

## Platform

Run under a shell where `opencode`, `yq`, `jq` are on PATH. On Windows that is
Git Bash (opencode is a native Windows binary), not WSL. On Linux/macOS any bash.

## Fan-in is NOT here

Dedup by `(file,line,category)`, agreement tiering, aggregate-ticket creation,
and fail-closed verification are the parent's job in main context (subagent-
reliability: cross-area merge + multi-step reasoning are not script/subagent
tasks). See `dispatch-review` skill → `references/model-matrix.md`.
