# Vendor Error Codes — Coding-Plan Endpoints

Per-vendor classification detail for the `coding-plan-limits` skill. Load when you need the exact code→class mapping for Kimi/Moonshot, Qwen/Alibaba, or GLM/Z.ai.

All three overload HTTP 429. Classify by the **numeric code / `error.type` / message**, not the status.

## Z.ai / Zhipu GLM (documented business-code table — richest signal)

Two-layer error: HTTP status + inner `error.code` (string) in the JSON body.

```json
{ "error": { "code": "1113", "message": "Insufficient balance..." } }
```

| code | Meaning | Class |
|------|---------|-------|
| 1302 | Rate limit reached | `transient_rate` |
| 1305 | Service temporarily overloaded | `transient_overload` (⚠️ also fires on content-fingerprint blocks) |
| 1113 | Insufficient balance / no resource package | `quota_terminal` |
| 1308 | Usage limit reached for `{n} {unit}`, resets at `{next_flush_time}` | `quota_windowed` |
| 1309 | GLM Coding Plan expired | `quota_terminal` |
| 1310 | Weekly/Monthly limit exhausted, resets at `{next_flush_time}` | `quota_windowed` |
| 1311 | Subscription does not include `{model_name}` | `plan_or_config` (switch model) |
| 1313 | Fair-usage-policy frequency limit | `plan_or_config` (don't retry) |
| 1314 | Enterprise package expired | `quota_terminal` |
| 1315 | API key limited to enterprise scenarios | `plan_or_config` (fix key) |
| 1316-1321 | 5h/7-day window / balance / monthly spend, resets at `{next_flush_time}` | `quota_windowed` |

Also: 1000/1001/1003 = 401 `auth`; 1210-1215 = 400 `invalid`; 1301 = content safety.

Traps:
- Windowed codes carry `{next_flush_time}` — parse and report it, don't retry.
- SSE mid-stream abort: reason is in the body `finish_reason`, not HTTP status.
- 1305 can be a fingerprint/content rejection masquerading as overload (field reports).
- Overload messages may be Chinese (`该模型当前访问量过大，请您稍后再试`) — match on `1305`, not text.

Source: https://docs.z.ai/api-reference/api-code ; models on plan: https://docs.z.ai/devpack/faq

## Moonshot / Kimi (`error.type` discrimination)

HTTP 429 for all rate/quota conditions; JSON `error.type` disambiguates. 403 = insufficient balance.

| `error.type` | Cause | Class |
|--------------|-------|-------|
| `rate_limit_reached_error` | Concurrency / RPM / TPM / TPD ceiling | `transient_rate` |
| `engine_overloaded_error` | Serving engine overloaded (honors Retry-After) | `transient_overload` |
| `exceeded_current_quota_error` | Insufficient balance / disabled / exhausted | `quota_terminal` |
| HTTP 403 | Insufficient permissions / balance | `quota_terminal` |

Facts:
- Four independent ceilings: concurrency, RPM, TPM, TPD.
- Limits are **account-level, not per-key** — more keys / switching models does NOT add capacity (shared pool).
- TPM reserves `input + max_completion_tokens` (not actual output) — high `max_completion_tokens` trips TPM early.
- `Retry-After` guaranteed only for `engine_overloaded_error`; not on every 429.

Source: https://www.kimi.com/en/help/kimi-api/api-error-codes ; https://www.kimi.com/help/kimi-api/api-rate-limits

## Alibaba DashScope / Qwen (OpenAI-compatible 429 + message text — weakest signal)

HTTP 429 with message text. No canonical machine-code table published for the LLM endpoint — classify by message.

| Message signal | Cause | Class |
|----------------|-------|-------|
| "Throttling" / QPM or TPM exceeded | Per-model throughput cap | `transient_rate` |
| "You exceeded your current quota" / "Insufficient Quota" | Billing/allowance exhausted | `quota_terminal` |
| `Throttling.RateQuota` / `Throttling.User` (classic OpenAPI surface) | Throttling | `transient_rate` |

- Rate dimension: QPM + TPM per model per workspace (configurable via `POST /api/v1/models/limits`).
- Error body is OpenAI-compatible in shape on the compatible endpoint (`error.code` / `error.message`).
- ⚠️ Biggest unknown: the retryable/terminal split rests on message text — fragile. Capture real 429 bodies to confirm. Coding/token-plan endpoints may differ in limits and context window (~170K vs claimed 1M reported).

Source: https://help.aliyun.com/zh/model-studio/qwen-api-via-dashscope ; https://help.aliyun.com/en/model-studio/update-model-rate-limits

## Anthropic (reference gold standard — how it *should* work)

Not a target vendor, but the cleanest signal to model against:
- `x-should-retry` boolean header — `true` = transient, `false` = hard cap. Trust it.
- `retry-after` (seconds) + `x-ratelimit-remaining-requests` / `-tokens` for pre-emptive throttling.
- 429 = your rate limit; **529** = Anthropic-side overload (longer backoff or switch model).

None of Kimi/Qwen/GLM publish an `x-should-retry` equivalent — classify client-side.

## Unknowns to verify empirically

- Qwen canonical business-code table (currently message-text only).
- Whether Kimi sends `Retry-After` on all 429 classes.
- Whether any of the three emit `x-ratelimit-remaining-*` headers (pre-emptive throttling).
- Fixed vs rolling window semantics for reset times.
- GLM 1305 overload-vs-fingerprint disambiguation.
