---
created_at: 2026-07-27T11:55:00-07:00
base_commit: 4d63baf
handoff_key: eval-infra-and-tooling
handoff_supersedes: weekend-queue
---

# Handoff

## Objective
Eval-infrastructure + multi-tool completeness workstream. Weekend queue (23/33/32/36/46) and Monday's 34/31 are closed; remaining frontier is 35/50/55/62/64 (+30 personal-only). `docs/plan.md` § "Frontier (2026-07-27, current)" holds the task graph with per-ticket lane + readiness — do not restate it elsewhere.

## Constraints
- CREW_ENV=corp — agy is mechanically blocked (init refuses, doctor flags, harness legs excluded with `policy-blocked (CREW_ENV=corp)`)
- **AWS decision (operator, 2026-07-27):** crush/Bedrock and any Bedrock judge spend use profile `sabiggin-isengard` (account 563171622587), region `us-west-2`
- Sandbox blocks `~/.aws` access — `ada credentials update` and `aws --profile` FAIL here; vend creds through the sandbox tooling instead (default profile, no `--profile` flag)
- Eval runs stay background per `.kiro/steering/eval-execution.md`; never edit `run.sh` mid-run

## Prior Decisions
- Identity hashes are relative-path based (machine-independent) so ticket 32 interchange joins cross-machine; `--changed-only` compares all three components (env drift ⇒ rerun)
- Rejudge rows carry the ORIGINAL hashes/env (outputs unchanged) plus a NEW `judges` field — judges is authoritative for who scored
- Ticket 34 built as a FOLD into `tools/session-analyzer/session_review.py` (not a standalone tool); digest-only, never creates tickets
- Blanket `tkt close --check-acs` REJECTED (ticket 50 records why): the manual box flip is the AC audit moment; only enumerated `--ac N,N` is acceptable
- Ticket 23 target miss (35% vs >50%) recorded as a finding, not reopened — remediation candidates in `docs/development/session-skill-usage-2026-07-25.md`
- Recall is now an EDITABLE install on this machine (pulls take effect immediately)

## Current State
Nothing mid-flight; tree clean, all pushed. Not yet in any file: ticket 35 is the natural next pickup and is fully unblocked EXCEPT for an explicit budget nod (~300-400 Bedrock judgments); its harness dependency (`--judge-only`) and account choice both landed today, so it can start immediately on approval.

Other lanes are active in this repo (recall workstream 51-63, Windows doctor work) — expect push rejections; rebase is clean and has worked 3× today. Their closes left `tkt validate` warnings at 20 (was 8): all unchecked-AC boxes on tickets 51-61/63/39, same benign class as the pre-tkt caveats, NOT our lane to re-triage.

## Next Steps
1. **Ticket 35** (needs budget nod) — shadow study: cheap candidates (haiku-4.5 prime) re-judge retained `results/2026-07-19T00-29-50Z` outputs via `run.sh --judge-only`; bar is median shift <5% AND mean bias within ±0.1; qualifying candidate AUGMENTS as a 5th leg on probation
2. **Ticket 50** — `tkt close/edit --ac N,N` (enumerated only; test-defined, ~1 session)
3. **Ticket 64** — research-first: does `sync-plan` gain a status-cell `--fix`? R9's report-only rationale must be quoted and weighed, not bypassed
4. **Ticket 55** — recall chunk-embedding cache (read the recall lane's context first)
5. Triage `.scratch/session-review-digest-2026-07-27.md` — 2 correction + 8 friction candidates from the new tooling, never triaged

## Fog
- Ticket 34's P1 recall gap: keyword-free corrections still escape the prefilter (one confirmed miss). The weekly LLM full-pass sketch in the spike digest is UNVALIDATED — don't build it without measuring
- Ticket 23's compliance ceiling: how much of the 65% non-compliance is legitimate skip conditions is unmeasured; the >50% target may be against the wrong denominator
- Bedrock prompt caching is disabled — the real cost of a crush/Bedrock judge leg for repeated-context judging is unmeasured (ticket 35 measures it; do not assume)

## Recommended Updates
- [ ] Delete `.scratch/archwright-digest-tkt.md` (carried from 07-21; `design/` holds the durable record)
- [ ] `.scratch/spike-34/` is superseded by the shipped `session_review.py` — safe to prune after ticket 34's digest is triaged
- [ ] Recall lane: a normalization pass would return `tkt validate` to a clean baseline (ticket 50's `--ac` flags would make it one line per ticket)

## Evidence
- Tickets 23/31/32/33/34/36/46 Resolutions carry per-AC evidence (all closed via `tkt close --note`); plan rows current; `sync-plan --check` clean
- Ticket 31 sentinel: `crush run --model bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0` → `OK`. Gotcha + model list + cost caveats: `.kiro/skills/deploy-toolkit/references/crush-bedrock.md`
- Ticket 34 validation: spike false-positive sessions excluded, previously-MISSED correction now caught and LLM-confirmed GENUINE
- Tried & failed today: `aws --profile` / `ada credentials update` (sandbox blocks `~/.aws`); bare Bedrock model ids in crush (needs `bedrock/us.` prefix); `uv tool install --force` alone (reuses cached wheel — `--reinstall` or `-e` required)
- New glossary terms: identity hash, shadow study, session review (`.memory/CONTEXT.md`)
