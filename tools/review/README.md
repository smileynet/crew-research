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

**Exit codes:** 0 = all expected reviewers produced a valid result; 1 = coverage
gap (≥1 indeterminate/missing); 2 = usage/environment error.

**Outputs** (in `.scratch/review/<RUN_ID>/`):
- `manifest.json`      — expected reviewer slugs (written before dispatch)
- `<slug>.jsonl`       — raw opencode JSONL per reviewer
- `<slug>.md`          — extracted final text (findings + REVIEW_RESULT line)
- `matrix-summary.json`— `{status, run_id, target, expected, produced, missing[], reviewers[]}`

## Validity rule (why exit code isn't trusted)

opencode's exit code is unreliable (can exit 0 on failure, hang, or surface 429
silently). A reviewer result counts as valid ONLY if its JSONL has a
`step_finish` with `reason:"stop"` AND non-empty assistant text AND a
`REVIEW_RESULT` line. Anything else → `indeterminate` → coverage gap (never
"clean"). Quota-exhausted reviewers (see `coding-plan-limits`) land here as
dropped reviewers, degrading the run without failing it.

## Platform

Run under a shell where `opencode`, `yq`, `jq` are on PATH. On Windows that is
Git Bash (opencode is a native Windows binary), not WSL. On Linux/macOS any bash.

## Fan-in is NOT here

Dedup by `(file,line,category)`, agreement tiering, aggregate-ticket creation,
and fail-closed verification are the parent's job in main context (subagent-
reliability: cross-area merge + multi-step reasoning are not script/subagent
tasks). See `dispatch-review` skill → `references/model-matrix.md`.
