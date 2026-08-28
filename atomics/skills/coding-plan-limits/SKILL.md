---
name: coding-plan-limits
description: "Handle quota, rate-limit, and capacity exhaustion on subscription/coding-plan LLM endpoints (Kimi/Moonshot, Qwen/Alibaba, GLM/Z.ai) in headless agents. Use when an agent runs on a coding plan, hits 429s, out-of-tokens, capacity, or 'overloaded' errors, or when building multi-model dispatch that must degrade gracefully. Trigger: 429, rate limit, quota exceeded, out of tokens, coding plan, capacity, overloaded, retry-after, insufficient balance, model fallback."
metadata:
  type: process
  invocation: both
  practice: null
---

# Coding-Plan Limits

Coding/token-plan endpoints WILL hit caps. Classify every error, then act — never silently hang or hot-loop.

## The core rule: HTTP 429 is overloaded — parse the body

All three vendors return **429 for several distinct conditions**. Status alone is never enough. Match on the **numeric/business code or `error.type`, NOT English message text** — GLM emits Chinese overload strings; text-matching fallback silently fails.

## Classify every error into one class

| Class | Meaning | Action |
|-------|---------|--------|
| `transient_rate` | RPM/TPM/QPM/concurrency ceiling | Retry: honor Retry-After → capped backoff |
| `transient_overload` | Server overloaded | Retry: honor Retry-After → capped backoff (bounded) |
| `quota_windowed` | Daily/weekly/monthly allowance used, resets at a time | Do NOT hot-retry; parse reset time; report + optionally schedule resume |
| `quota_terminal` | Balance out, plan expired | **Fail-closed** — retries waste budget |
| `plan_or_config` | Plan excludes model / wrong key type | **Fail-closed** — switch model or fix key |
| `auth` (401) / `invalid` (400) | Bad key / bad request | **Fail-closed** — no retry |

Per-vendor code tables (GLM 1302/1305/1308-1321, Kimi `error.type`, Qwen message text) → [references/vendor-codes.md](references/vendor-codes.md).

## Handling order (transient classes only)

1. **Honor `Retry-After`** if present — it's more accurate than any client formula.
2. **Capped exponential backoff + jitter** — 1s initial, ×2, 30s cap, ±20-50% jitter, **≤5 attempts**.
3. **Concurrency queue BEFORE the retry layer** — retries can't fix excessive parallelism. Kimi limits are account-level (shared across all models/keys).
4. **Circuit breaker** — after N consecutive 429s, STOP issuing requests. This converts a silent infinite loop into fail-closed-with-evidence.
5. **Hard wall-clock deadline** on the whole operation, in addition to the attempt cap.

Do NOT retry `quota_terminal`, `plan_or_config`, `auth`, `invalid` — they never succeed.

## Model fallback (multi-model dispatch)

- On sustained `transient_overload` or `plan_or_config` (model unavailable), route to another model in the matrix.
- **Match the fallback trigger on the numeric code**, never message substrings.
- In a matrix run, a quota-exhausted model **degrades the run** (continue with remaining models, report the gap) rather than failing the whole review.

## Emit structured status (never swallow, never hang)

Every terminal or exhausted-retry outcome emits machine-readable status (aligns with the Validation Contract):

```json
{"status":"fail","reason":"quota_exhausted","vendor":"zai","code":"1310",
 "resets_at":"2026-08-29T00:00:00Z","retryable":false,
 "message":"Weekly limit exhausted; resets at next_flush_time","action":"switch_model_or_wait"}
```

Exit non-zero on fail-closed. Log every retry with its classified type + delay — never retry silently.

## Traps

- **SSE mid-stream failures** (GLM): the failure reason is in the streamed body's `finish_reason`, NOT the HTTP status. Parsing only status treats a truncated stream as success.
- **429 on first request with healthy quota**: possibly overload or a content-fingerprint block (GLM 1305 double-meaning), not real exhaustion. One short backoff, then fail-closed with the raw error.
- **GLM 1305** means "overloaded" but also fires on fingerprinted prompts — treat persistent 1305 as possibly non-transient.
- **Kimi TPM** reserves `input + max_completion_tokens` (not actual output) — a high `max_completion_tokens` trips TPM early.
