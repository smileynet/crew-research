---
id: "168"
title: "Spike: empirically probe v3 default engine headless on 2.27.0 (schema, trust, API key)"
status: in_progress
blocked_by: []
priority: high
tags: [kiro-v3]
---

# Spike: empirically probe v3 default engine headless on 2.27.0

## Why now

The ticket-79 spike (2026-08-11) and ticket-125 (2026-08-26, kiro-cli 2.19.2)
concluded **v3 could not run headless** and standardized the harness on
`--agent-engine v2`. That is now stale. Research 2026-10-02
(`.scratch/research/kiro-v3-2026-10/` + `.scratch/research/t168/`, 7 subagent
reports, web + internal) establishes on the installed **kiro-cli 2.27.0**:

- The binary labels `--v2` "the pre-3.0 default" and headless `--no-interactive`
  returned the exact string, exit 0.
- v2 is soft-deprecated (notice in 2.26.0); sessions moved to SQLite
  (`~/.local/share/kiro-cli/data.sqlite3`, `conversations_v2`), JSONL still
  dual-written on 2.27.0.

This spike nails down the empirical facts every downstream v3 ticket (126, 169,
recall-74) depends on. **Hardened 2026-10-02** after research+review subagents
surfaced three findings the first draft missed (see "What research changed").

## What research changed (read before running)

1. **🔴 v3 non-interactive may not discover skills — a harness false-negative, not
   a test result.** An internal ChangeLog (2026-09-22, `w.amazon.com/bin/view/Users/nnaohir/research/kiro-cli-v2-features/ChangeLog`)
   records a **confirmed bug: V3 in non-interactive mode cannot discover agent
   skills** (verified vs V2). GitHub #7565 separately reports `--no-interactive`
   not firing steering-mandated tool calls (closed "not planned", repro'd, never
   refuted for v3). **Consequence:** a probe asserting "my skill/steering activated
   under v3 headless" can FALSE-NEGATIVE from the engine, not the setup. The spike
   MUST include a v2-vs-v3 skill-discovery A/B so we can tell "v3 is broken here"
   from "our fixture is wrong" — and must NOT conclude crew-research skills are
   broken on v3 without that control.

2. **v3 may not actually be the default yet on this build.** Internal sources say
   the staged default rollout *started* 2026-09-11 with a *target* of mid-October
   2026; "V3" ships inside the 2.x train, not a 3.x number. The 2.27.0 `--help`
   wording strongly implies the flip, but the two signals conflict. **The probe
   must DETECT the active engine from the stream (`runStarted.data.engine`), never
   assume it from version/date.**

3. **Auth is a two-plane model; `permissions.yaml` is likely a non-thing here.**
   `KIRO_API_KEY` authenticates the Kiro *inference* backend only (Pro-tier; NOT a
   Midway credential); Midway authenticates builder-mcp internal tools; the planes
   are independent (authoritative: `w.amazon.com/bin/view/AEE_SE_Team/KiroHeadless`).
   On THIS host (review 07): **no KIRO_API_KEY is set, no global
   `~/.kiro/settings/permissions.yaml` exists, auth is Midway**, yet headless ran —
   so determine what actually served the inference call (assert the `Credits:`/
   finalText). No source found a headless `permissions.yaml` trust file — trust is
   governed by `--trust-*` flags + agent-config `allowedTools`. Drop the original
   ticket's "permissions.yaml" framing.

## Open questions to resolve

1. **v3 stream-json event schema.** ticket-125 captured the v2 ACP-v1 vocabulary
   (`runStarted`/`metadata`/`sessionUpdate`/`runFinished`; content as
   `agent_message_chunk`; `tool_call`/`tool_call_update` with `_meta.kiro.toolName`).
   ACP v1 is stable (research 01) so names *should* be identical IF v3 still
   negotiates `acpProtocolVersion:1` — capture a real v3 stream and confirm the
   kiro wrapper events + the ACP version. Match BOTH `tool_call` and
   `tool_call_update` in any extraction (ACP v2 would fold them).
2. **Does `--trust-all-tools` / `--trust-tools=` work under headless v3?** On 2.19.2
   v3 *rejected* `-a`. Docs + internal pipelines say trust flags are the working CI
   path; GitHub #7398 reports `--trust-all-tools` adding a startup confirmation
   prompt (Closed, no fix merged) that can hang `--no-interactive`. Test both flags
   on v3 and record actual behavior + exit codes.
3. **Does headless v3 require `KIRO_API_KEY` on this account?** It's unset here and
   headless worked — determine whether that was v2, a persisted/Midway-backed
   session, or genuine keyless v3. Check `kiro-cli whoami --format json` (reports
   account type `ApiKey` vs `BuilderId`/`IamIdentityCenter`).

Secondary (cheap while here):
- Default engine for a plain `kiro-cli chat --no-interactive` (no flag) on 2.27.x.
- `--agent-engine v2` still works (regression guard for the pinned path).
- `--require-mcp-startup` behavior: v3 exits **code 3** on MCP failure / no status
  in 30s — order probe timeout > 30s so the two don't conflate (research 04/03).
- v3 interruption record shape (new terminal-ish event for interrupted runs).
- Trusted-workspace gate: in an untrusted/fresh workdir v3 tightens MCP+shell
  approval (2.26.0); headless has no human to approve → silent capability loss
  unless trust granted upfront. Observe, don't assume a single "no-load" switch.

## Method

Linux timeout wrapper (research 03): **`timeout -k 5s 60s <cmd>`** — SIGTERM at
60s, guaranteed SIGKILL 5s later (v3 can block TERM when wedged; `-k` is
mandatory). Exit **124** = timed out, **137** = had to be SIGKILLed (really hung) →
run PID cleanup after a 137. Do NOT use `--foreground` (we want the whole process
group killed). Let `timeout` own the group — no hand-rolled `setsid`.

Isolation (reuse the proven harness pattern — review 05):
- `mktemp -d` workdir + `cd` into it (fixtures via cwd walk-up); delete-after.
- `KIRO_HOME=$workdir/.kiro` to block global steering leaking in. NOTE (ticket-125
  item 5, still open): KIRO_HOME redirects config *reads*; unverified whether it
  redirects the session *write* path — eyeball `~/.kiro/sessions/` after.
- Separate streams: `> events.jsonl 2> err.log` (NEVER `2>&1` — merging corrupts JSON).
- **Containment guard, every run:** `sha256sum` of `~/.kiro/settings/` before/after
  (diff = hard stop) + `git status --porcelain` clean-check.
- **Never** write a user-global `permissions.yaml` allow-all (weakens live sessions).
- **PID cleanup:** rely on `timeout -k` group-kill; if scanning, bracket trick
  `ps -eo pid,command | grep "[k]iro-cli chat"`, identify the active session by
  UUID/lock-holder NOT recency, never `pkill -f kiro` (self-match killed a kiro
  shell before).

Matrix (one invocation at a time, per project convention; each `timeout -k 5s 60s`):

| # | Command (under isolation) | Captures |
|---|---------------------------|----------|
| 1 | `--agent-engine v3 --output-format stream-json "Reply with exactly: OK"` | v3 wrapper event types + `runStarted.data.engine` + `acpProtocolVersion`; diff vs v2 (ticket-125) |
| 2 | `--agent-engine v3 --output-format stream-json "Read ./canary.txt and quote it"` | v3 `tool_call`/`tool_call_update` shape + `_meta.kiro.toolName` path |
| 3 | `--agent-engine v3 --trust-all-tools "Reply OK"` | does `-a` work on v3 now? (#7398) exit code |
| 4 | `--agent-engine v3 --trust-tools=read "Read ./canary.txt and quote it"` | least-privilege trust path on v3 |
| 5 | plain `--no-interactive --output-format stream-json "Reply OK"` (NO engine flag) | **which engine is default headless** (read `runStarted.data.engine`) |
| 6 | `--agent-engine v2 --output-format stream-json "Reply OK"` | v2 regression guard |
| 7 | **Skill-discovery A/B** (🔴 critical): a tmp skill with a canary description; run the SAME activating prompt once `--agent-engine v2` and once `v3`, both `--trust-all-tools`, in a *trusted* workdir | isolates the 2026-09-22 skill-discovery bug from fixture error — if v2 activates and v3 doesn't, that's the engine bug, cite it; do NOT blame crew-research skills |
| 8 | run #1 from a fresh/untrusted workdir | trusted-workspace gate effect on headless |

Auth probe (no secret echo): `env | grep -i kiro_api | sed 's/=.*/=<set>/'`;
`kiro-cli whoami --format json 2>/dev/null`. Record whether v3 runs succeed with
no KIRO_API_KEY and what account type `whoami` reports.

Known false-signal guards (research 04): MCP tools needing Midway are blocked
headless (two-plane model) — don't attribute their absence to the engine; a slow
MCP server can trip `--require-mcp-startup`'s 30s → exit 3; 2.24.0 stopped
auto-loading project `.env` into tools.

## Reuse vs build-new (review 05)

REUSE (exists, proven): isolation pattern (`proofs/harness/run.sh:258-259,305`;
empty-home variant `run-proof.sh:71-73`); engine-flag idiom
(`evals/harness/run.sh:438-439` — `[[ -n "$ENGINE" ]] && engine_flag="--agent-engine $ENGINE"`);
v2/v3 session-format detector (`extract-session-summary.sh:49-73`, validate the
captured v3 schema against its field assumptions); ticket-125 inline script as a
template (adapt trust flags for v3). BUILD NEW: the v3 capture itself (no
`discover-stream-json.sh` exists — glob confirms 0 files); the schema delta doc.

## Deliverable

`tools/proofs/docs/v3-engine-notes.md` (promote from
`.scratch/research/t168/` if it stays scratch):
- v3 vs v2 stream-json schema delta (or "identical ACP v1, confirmed") with the
  `runStarted.data.engine` + `acpProtocolVersion` evidence
- Trust-flag behavior under headless v3 (works / regressed / rejected) + exit codes
- KIRO_API_KEY / whoami verdict for headless v3 on this account (two-plane note)
- Default-engine-when-unflagged verdict
- **Skill-discovery A/B result** (v2 vs v3) — the gating finding for whether
  crew-research skills even function under v3 headless
- Trusted-workspace gate effect; MCP/Midway two-plane caveat
- Per-ticket unblock mapping: 126 (adapter engine selector + trust swap),
  169 / recall-74 (unaffected by engine; SQLite is separate), and whether the
  skill-discovery bug blocks any v3-headless eval/activation work

## Acceptance criteria

- [x] Active engine DETECTED from `runStarted.data.engine` for the unflagged run (not assumed)
- [x] v3 stream-json schema captured on 2.27.0 and diffed against v2 (ticket-125) — same or delta documented, with `acpProtocolVersion` recorded
- [x] `--trust-all-tools` AND `--trust-tools=read` behavior under headless v3 recorded with exit codes (resolves #7398 for our use)
- [x] KIRO_API_KEY requirement + `whoami` account type for headless v3 on this account determined
- [x] **Skill-discovery A/B (v2 vs v3) run; result states whether the 2026-09-22 skill-discovery bug reproduces on 2.27.0** — distinguishing engine bug from fixture error
- [x] v2 path confirmed still working (no regression)
- [x] Findings written to deliverable with per-ticket unblock mapping
- [x] Containment verified: `~/.kiro/settings/` sha256 unchanged, `git status` clean, no user-global permissions.yaml created, no stray/hung kiro-cli PIDs left (clean up any 137s)
