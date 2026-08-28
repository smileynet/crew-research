---
id: "127"
title: "Extend dispatch review to opencode with multi-model matrix"
status: in_progress
blocked_by: []
priority: high
---

# Extend dispatch review to opencode with multi-model matrix

## Goal

Extend the independent-review dispatch (currently Codex-only, via the `dispatch-codex-review` skill) to ALSO use **opencode**, with the ability to run **multiple opencode sessions across a matrix of models**. Different model families catch different issues — a single reviewer has blind spots.

## Research-backed findings (2026-08-28, `.scratch/research/t127/`)

### opencode headless invocation — CONFIRMED [L4]

```bash
opencode run --auto -m <provider>/<model> "<prompt>"
```
- `opencode run "<prompt>"` = the `codex exec` equivalent (non-interactive, runs full agent loop, exits)
- `--auto` = the sandbox-bypass equivalent (auto-approves anything not explicitly denied; opencode has NO OS sandbox, uses a permission engine that already defaults mostly to `allow`). This lets the reviewer run tests/linters/git.
- `-m provider/model` = **per-invocation** model selection (highest precedence, doesn't mutate config). Format always `provider/model`, e.g. `anthropic/claude-sonnet-4-5`, `openai/gpt-5.1-codex`.
- `--format json` for parseable output; `opencode models` to enumerate valid ids.
- Auth: env vars / `.env` auto-loaded at startup (CI-friendly), or `opencode auth login`.
- ⚠️ `shell` tool is non-interactive (no PTY) — commands awaiting input hang. Unknowns to verify empirically: exit-code-on-failure (CI gating), `--format json` schema, native-Windows headless recipe.

### opencode already first-class in crew-research (ticket 121, done) [L1]

- `--tool opencode` deploys skills to `~/.config/opencode/skills/`, steering into `AGENTS.md`. Adapter exists at `tools/proofs/adapters/opencode.yaml` (`opencode run "{query}"`, timeout 300). **Gap: no `--model` flag in the adapter invoke** (CloseCode's adapter proves the `-m provider/model` pattern).
- opencode is **unrestricted in all environments** (corp/personal/unset) — safe to add everywhere.

### The dispatch skill is ~80% tool-agnostic [L1]

Codex-bound in exactly these places (both `dispatch-codex-review` and `review-new-work`): skill name/description, `codex exec` invocation, `CODEX_REVIEW_RESULT` result prefix, `.codex/review-marker.json` path + `"reviewer":"codex"` field, ticket `Reporter: Codex` / `Codex confidence` labels, and the sandbox rationale prose. **Tool-agnostic (reusable as-is):** RUN_ID+TARGET correlation, result-JSON shape, fail-closed Verify algorithm, two-axis review methodology, ticket field requirements. Note: `frontier-work.md` keys its unconfirmed-reproduction rule on `Reporter: Codex` — that consumer needs updating too.

## Design tension → RESOLVED (correlation vs. concurrency)

The gate flagged: N concurrent reviewers each creating a findings ticket → ID-allocation races + fail-closed correlation must survive. Research resolves it decisively:

**Decision: parent-aggregates (single-writer fan-in).** Reviewers write structured findings to per-model artifact files at pre-known paths (`.scratch/review/<RUN_ID>/<provider-model-slug>.md`); the **parent** (main context) reads all, dedups cross-model, and creates **ONE** aggregate findings ticket. Rationale [L4 AWS/Azure fan-out-fan-in + subagent-reliability]:
- Ticket creation stays single-threaded → zero ID-race (no N contending `tkt` pushes)
- Cross-model dedup MUST happen in main context anyway (subagent-reliability: cross-area merge is not a subagent task)
- Parent writes a manifest of expected model-slugs pre-dispatch → fan-in reconciles produced-vs-expected, detects missing reviewers (coverage-gap reporting)
- Matches existing crew-research write-then-read + manifest pattern

Rejected: per-model tickets via `tkt batch` pre-allocation (works — batch is atomic single-push — but multiplies frontier noise and complicates the one-aggregate-ticket invariant). Rejected: each reviewer runs `tkt new` (hits the concurrent-subagent-push reliability hazard).

## Aggregation & dedup (from multi-model prior art [L1 Greptile, L5])

- Require **structured JSON findings** (typed severity/location/category). Dedup by grouping on **location+category**, NOT fuzzy text.
- Classify by agreement into tiers: **Consensus** (≥2 models), **Majority**, **Individual** (single model — keep, labeled low-confidence: "solo findings are where interesting insights hide").
- Tag every finding with `Reviewer: <provider/model>`. Keep it **advisory, not blocking**.
- Evidence it's worth it: uncorrelated reviewers decorrelate errors (3× 70% reviewers → ~90%+ catch); a model misses the bug categories it introduces. Family diversity (Claude + GPT + Gemini) is the lever, not re-running one model.
- Pitfall: union-everything = nit flood. False positives are the real cost — tier + confidence-label to manage.

## What to build

1. **Generalize to a `dispatch-review` skill** (supersede/alias `dispatch-codex-review`): parameterize `reviewer = codex | opencode:<model>`. Result prefix → tool-neutral `REVIEW_RESULT ` with a `reviewer` field. Preserve RUN_ID/TARGET/fail-closed contract verbatim.
2. **Add `-m provider/model` + `--auto`** to opencode adapter invoke; verify exit codes and `--format json` empirically.
3. **Matrix runner**: parent takes a model list, dispatches one `opencode run` per model (each in `mktemp -d` workdir, per eval-execution containment), writes per-model findings artifact. Bounded-parallel or sequential (one blocking command at a time per steering).
4. **Parent fan-in**: read all artifacts against the pre-written manifest, dedup by location+category, tier by agreement, create ONE aggregate ticket tagged per-model.
5. **Matrix config surface**: a dispatch config (NOT known-tools.yaml — opencode is a deploy target, not self-deploying). Decide: default model set vs. user-supplied list.
6. **Update `frontier-work.md`** provenance matching (`Reporter:` no longer always Codex).
7. **New skill `coding-plan-limits`** — handling quota/capacity exhaustion on subscription-plan endpoints (see below). Reviewers must not silently hang or hot-loop when a plan runs out of tokens.

## Target model matrix (all on vendor CODING/TOKEN plans) — LIVE-VERIFIED 2026-08-28

opencode 1.18.21. All three providers already authenticated (`opencode auth list`): Kimi For Coding, Alibaba Token Plan, Z.AI Coding Plan. All ids confirmed present in `opencode models --refresh` (485 models) and Kimi smoke-tested (`opencode run --auto -m kimi-for-coding/k3 "..."` → returns output headless).

| # | Model | Plan | opencode `-m` id (CONFIRMED) | Auth |
|---|-------|------|------------------------------|------|
| 1 | Kimi K3 | Moonshot Kimi coding plan | `kimi-for-coding/k3` (also `/k3-256k`) | ✅ Kimi For Coding |
| 2 | Qwen 3.8 Max | Alibaba Token Plan | `alibaba-token-plan/qwen3.8-max` (built-in provider) | ✅ Alibaba Token Plan |
| 3 | GLM 5.3 | Z.ai coding plan | `zai-coding-plan/glm-5.3` (also `-flash`, `-highspeed`) | ✅ Z.AI Coding Plan |

Corrections to earlier research: Kimi coding-plan path is `kimi-for-coding/k3` (NOT `moonshot/kimi-k3`); Alibaba Token Plan is a **built-in** opencode provider (no custom `@ai-sdk/anthropic` block needed); `zai-coding-plan/glm-5.3` confirmed verbatim.

## Coding-plan quota handling (new `coding-plan-limits` skill)

All three run on subscription plans that WILL hit token/capacity caps. Agents must classify and act, never silently hang or hot-loop. Research [L4 vendor docs, 24 sources]:

- **All vendors overload HTTP 429 — status alone is insufficient; parse the body.** Match on **numeric error code, NOT English message text** (GLM emits Chinese overload strings; text-matching fallback silently fails — openclaw #93211).
- **Classify every 429/error into:** `transient_rate` / `transient_overload` (retry w/ backoff), `quota_windowed` (wait for `{next_flush_time}`, don't hot-retry), `quota_terminal` / `plan_expired` / `plan_excludes_model` / `auth` / `invalid` (fail-closed — retries waste budget, never succeed).
- **Vendor specifics:**
  - Z.ai/GLM: business `error.code` — 1302 rate (retry), 1305 overload (retry; also content-fingerprint), 1113 insufficient balance (terminal), 1308/1310/1316-1321 windowed quota + reset time, 1309/1314 plan expired (terminal), 1311 plan excludes model (switch), 1313 fair-use (terminal). SSE mid-stream failures surface in `finish_reason`, not HTTP status.
  - Kimi/Moonshot: 429 + `error.type` — `rate_limit_reached_error` (retry), `engine_overloaded_error` (honor Retry-After, retry), `exceeded_current_quota_error` (terminal); 403 insufficient balance. Account-level limits shared across all models.
  - Qwen/DashScope: 429 + message text; "exceeded your current quota" (terminal) vs throttling (retry). Weakest docs — no canonical code table (biggest unknown).
- **Handling order:** honor Retry-After → capped exp backoff w/ jitter (1s→30s, ≤5 attempts) for transient only → circuit-breaker after N consecutive 429s (converts silent-loop into fail-closed-with-evidence) → fallback to another matrix model (match on numeric code) → emit structured JSON status (`{status, reason, vendor, code, resets_at, retryable, action}`) per the project Validation Contract.
- **Matrix implication:** if one model is quota-exhausted, the review continues with the remaining models (degraded coverage, reported in the manifest reconciliation) rather than failing the whole run.

## Open questions (resolve during build)

- opencode `--format json` event schema + exit-code-on-failure (empirical)
- Exact live model ids for all 3 (verify first — see matrix warning)
- Does opencode surface the vendor error body/code, or swallow it? (determines how the skill detects quota state)
- Marker file: shared `.review/` with plural `reviewers:[]` vs per-model markers
- Native-Windows opencode headless recipe (or WSL like init.sh?)

## Acceptance criteria

- [ ] Live-verified opencode ids recorded for Kimi K3, Qwen 3.8 Max, GLM 5.3 (with provider config for Alibaba custom provider)
- [ ] `dispatch-review` skill: reviewer is a param (codex | opencode:model); tool-neutral `REVIEW_RESULT` contract; fail-closed verify preserved
- [ ] opencode single-model review end-to-end: dispatch → per-model artifact → parent aggregate ticket (pushed) → fail-closed verify
- [ ] Matrix launches the 3 target models (one opencode session each), isolated in temp workdirs
- [ ] `coding-plan-limits` skill: classifies 429s by numeric code, distinguishes transient/windowed/terminal, backoff+circuit-breaker, structured status, model fallback — never silent hang/loop
- [ ] Quota-exhausted model degrades gracefully (run continues with remaining models; gap reported)
- [ ] Parent fan-in dedups by location+category, tiers by agreement (Consensus/Majority/Individual), tags findings per-model — done in main context
- [ ] No ticket-ID races (single-writer aggregate ticket; manifest reconciliation detects missing reviewers)
- [ ] Codex path unchanged (no regression to existing dispatch-codex-review behavior)
- [ ] opencode adapter gains `-m provider/model` + `--auto`; exit codes + json schema documented
- [ ] `frontier-work.md` provenance matching updated; `mise run validate` + lint pass
