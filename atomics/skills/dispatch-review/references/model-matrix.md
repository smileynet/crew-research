# Model Matrix (opencode multi-model review)

Run the same review through several model families in parallel — different
families catch different issues (a model tends to miss the bug categories it
itself would introduce). Family diversity is the lever, not re-running one model.

## Default matrix (all on vendor coding/token plans, live-verified 2026-08-28)

| Model | opencode `-m` id | Auth (opencode auth list) |
|-------|------------------|---------------------------|
| Kimi K3 | `kimi-for-coding/k3` | Kimi For Coding |
| Qwen 3.8 Max | `alibaba-token-plan/qwen3.8-max` | Alibaba Token Plan |
| GLM 5.3 | `zai-coding-plan/glm-5.3` | Z.AI Coding Plan |

All three are built-in opencode providers (no custom provider block). Verify ids
live with `opencode models --refresh` then `opencode models <provider>`.
Invocation: `opencode run --auto -m <id> "<prompt>"`.

## Fan-out / fan-in (single-writer parent aggregation)

1. **Parent pre-writes a manifest** listing the expected reviewer slugs for this
   `RUN_ID` (`.scratch/review/<RUN_ID>/manifest.json`).
2. **Dispatch one reviewer per model.** Use the fan-out helper
   `bash tools/review/matrix.sh --run-id <uuid> --target <sha> [--models a,b,c]`
   (or the host subagent facility). It runs each `opencode run --auto -m <id>
   --format json` reviewer, validates by `step_finish reason:"stop"` + non-empty
   text + a `REVIEW_RESULT` line (NOT exit code), writes each reviewer's findings
   to `.scratch/review/<RUN_ID>/<slug>.md`, and emits
   `.scratch/review/<RUN_ID>/matrix-summary.json` `{status, expected, produced,
   missing[], reviewers[]}`. A quota-exhausted or degraded reviewer is recorded
   as `indeterminate` (a coverage gap), never dropped silently.
3. **Parent fan-in (main context only)** reads all per-model artifacts against
   the manifest / `matrix-summary.json`, reconciles produced-vs-expected (each
   `missing` entry = a reported coverage gap, NOT clean), then creates **ONE**
   aggregate findings ticket via `tkt new` (single writer → no ID race).
   Fail-closed: any `indeterminate`/`missing` reviewer means the target is not
   fully covered — report it, do not report clean.

Cross-model dedup MUST happen in main context (subagent-reliability: cross-area
merge is not a subagent task).

## Aggregation & dedup

- Require **structured findings** (typed severity / location / category).
- Dedup by grouping on **location + category**, NOT fuzzy text.
- Tier by agreement: **Consensus** (≥2 models), **Majority**, **Individual**
  (single model — KEEP, labeled low-confidence; solo findings are often the real
  bug). Tag every finding `Reviewer: <provider/model>`.
- Advisory, not blocking. The union-everything trap = nit flood; tier +
  confidence-label to manage false positives.

## Quota / capacity handling

Reviewers run on subscription plans that hit caps. Follow `coding-plan-limits`:
classify errors by numeric code (not English text), backoff transient, fail-closed
terminal, and **degrade the matrix gracefully** — a quota-exhausted model drops
out of the run (reported in manifest reconciliation) rather than failing the whole
review. A dropped model is an `indeterminate` result for that reviewer, never a
`clean`.

## Parsing opencode output (verified opencode 1.18.21)

`opencode run --auto --format json -m <id> "<prompt>"` emits JSONL on stdout
(envelope `{type, timestamp, sessionID, part{...}}`). Capture stdout/stderr
separately (`> events.jsonl 2> logs.txt`, never `2>&1`).

```bash
# Final assistant text
jq -rn '[inputs | select(.type=="text") | .part.text] | join("")' events.jsonl
# Clean-stop check (must be present for a valid result)
jq -rn 'last(inputs | select(.type=="step_finish") | .part.reason) // "none"' events.jsonl
```

**Exit code is NOT trustworthy** — opencode can exit 0 on failure, hang, or
surface 429 silently. A result counts as valid ONLY if a `step_finish` with
`reason:"stop"` is present AND a non-empty final text / `REVIEW_RESULT` line was
produced. Otherwise → `indeterminate` (deny). Wrap every invocation in a timeout
(opencode has no built-in run timeout).

## Concurrency

Bounded parallel or sequential — respect subagent concurrency limits and run one
blocking CLI invocation at a time (shell-serialization). Each `opencode run` is
its own session; safe to run alongside other sessions.
