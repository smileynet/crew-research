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
concluded **v3 could not run headless** ("v3 has no non-TUI code path on this
build") and standardized the harness on `--agent-engine v2`. That conclusion is
now **stale**. Research 2026-10-02 (`.scratch/research/kiro-v3-2026-10/`) found that
on the installed **kiro-cli 2.27.0**:

- v3 is the **default** engine (binary labels `--v2` "the pre-3.0 default").
- Headless works: `kiro-cli chat --no-interactive` returned the exact string, exit 0.
- v2 is soft-deprecated (deprecation notice in 2.26.0; no removal date).

The backlog tickets (126, and recall-side) all gated on "when v3 ships non-TUI
headless / becomes default" — that trigger has fired. Before building any adapters
(126) or the SQLite reader, three facts must be nailed down empirically. This spike
is the de-risk gate for all downstream v3 work.

## Open questions to resolve (the whole point)

1. **v3 stream-json event schema.** ticket-125 captured the **v2** ACP-v1 vocabulary
   (`runStarted`/`metadata`/`sessionUpdate`/`runFinished`, `_meta.kiro.toolName`).
   Does the **v3** engine emit the same `type` names? Research could only infer
   compatibility from the shared ACP framing. Capture a real `--agent-engine v3`
   stream and diff against the documented v2 schema in
   `tools/proofs/docs/` / `.scratch/research/t125/`.
2. **Does `--trust-all-tools` work under headless v3?** On 2.19.2 v3 *rejected* `-a`
   ("not supported with --agent-engine=v3"). Docs now say trust flags persist as the
   session scope and are the CI path, but GitHub #7398 reports `--trust-all-tools`
   regressing the confirmation prompt. Test `--no-interactive --trust-all-tools`
   AND `--trust-tools=` on v3 and record actual behavior.
3. **Does headless v3 require `KIRO_API_KEY`?** Docs state headless needs a Pro-tier
   `KIRO_API_KEY`. The 2026-10-02 probe ran headless with no key set — determine
   whether that was v2 fallback, a cached session, or whether v3 headless genuinely
   works without the key on this account.

Secondary (cheap to capture while here):
- Default engine for a plain `kiro-cli chat --no-interactive` (no engine flag) on
  2.27.x — is permissions.yaml even consulted?
- Does `--agent-engine v2` still work (regression guard for the pinned harness path)?
- Trusted-workspace gate: does a fresh/untrusted workspace fail to load
  skills/steering/MCP in headless (v3 new behavior)? Affects CI.
- v3 interruption record shape (the new terminal-ish event for interrupted runs).

## Method

Run from a `mktemp -d` workdir with `.kiro/` fixtures (never mutate global config
or `~/.kiro/settings/permissions.yaml` — see ticket-125 disruption analysis). Wrap
each potentially-hanging invocation with a timeout so the session can't wedge
(ticket-125 recorded the hang on 2.19.2):

```bash
timeout 60 kiro-cli chat --no-interactive --agent-engine v3 --output-format stream-json \
  "Reply with exactly: OK" > v3.jsonl 2>v3.err || echo "exit=$?"
```

Matrix (one invocation at a time, per project convention):

| # | Command | Captures |
|---|---------|----------|
| 1 | `--agent-engine v3 --output-format stream-json "Reply OK"` | v3 event `type` vocabulary; compare to v2 |
| 2 | `--agent-engine v3 --output-format stream-json "Read ./canary.txt and quote it"` | v3 tool_call shape |
| 3 | `--agent-engine v3 --trust-all-tools "Reply OK"` | does `-a` work on v3 now? (#7398) |
| 4 | `--agent-engine v3 --trust-tools= "Reply OK"` | trust-nothing path |
| 5 | plain `--no-interactive "Reply OK"` (no engine flag) | which engine is default headless |
| 6 | `--agent-engine v2 ... "Reply OK"` | v2 regression guard |
| 7 | run #1 from an untrusted fresh workdir | trusted-workspace gate effect on skills loading |

For KIRO_API_KEY: note whether it is set (`env | grep -i kiro_api` — do NOT echo the
value), and whether v3 headless runs succeed/fail without it.

## Deliverable

`.scratch/research/kiro-v3-2026-10/05-v3-headless-probe.md` (or promote to
`tools/proofs/docs/v3-engine-notes.md` if it becomes a harness reference):
- v3 vs v2 stream-json schema delta (or "identical, confirmed")
- Trust-flag behavior under headless v3 (works / regressed / rejected) with exit codes
- KIRO_API_KEY requirement verdict
- Default-engine-when-unflagged verdict
- Trusted-workspace gate effect on CI
- Explicit list of which downstream tickets (126, 169, recall-74) each finding unblocks

## Acceptance criteria

- [ ] v3 stream-json schema captured on 2.27.0 and diffed against v2 (ticket-125) — same or delta documented
- [ ] `--trust-all-tools` / `--trust-tools=` behavior under headless v3 recorded with exit codes (resolves #7398 question for our use)
- [ ] KIRO_API_KEY requirement for headless v3 determined (required / not-required on this account)
- [ ] Default engine for unflagged `--no-interactive` on 2.27.x confirmed
- [ ] v2 path confirmed still working (no regression to pinned harness)
- [ ] Findings written to deliverable file with per-ticket unblock mapping
- [ ] No global config / permissions.yaml mutated (git-clean + no `~/.kiro/settings` change)
