---
created_at: 2026-07-25T01:35:00+00:00
base_commit: b0d48de
handoff_key: weekend-queue
---

# Handoff

## Objective
Weekend goal-queue COMPLETE: tickets 23, 33, 32, 36, 46 closed; ticket 34 spike executed (ticket stays open — build/defer/fold is Monday's decision). Next-week reserved set untouched: 30 (personal machine), 31 (needs AWS profile choice), 35 (judge spend + cleaner post-32), 39 (Windows machine).

## Constraints
- CREW_ENV=corp — now MECHANICALLY enforced (ticket 36): init refuses agy, doctor flags artifacts, harness legs excluded with `policy-blocked (CREW_ENV=corp)`
- Eval results on this machine are kiro-only-judged; ticket 32's `--judge-only` exists precisely to upgrade them later

## Prior Decisions
- Ticket 23 target miss recorded as finding, NOT re-opened: 35% post-gate vs 29% reference (+6pts, <50% target). Remediation candidates in `docs/development/session-skill-usage-2026-07-25.md` (denominator refinement / mechanical enforcement / 30d re-measure ~08-17)
- Identity hashes are relative-path based (machine-independent) — deliberate, so ticket 32 interchange joins work cross-machine
- `--changed-only` compares all 3 components (env drift = rerun); relax only if practice demands
- Rejudge rows carry ORIGINAL hashes/env (outputs unchanged) + new `judges` — the judges field is authoritative for who scored

## Current State
All green: tkt suite 51 passed; sync-plan 0 findings; tkt validate pass (8 deliberate pre-tkt caveat warnings); compositions validate + lint clean (1 pre-existing image-handling warning); 12/12 archwright static checks; everything pushed. Only the evidence ledger (auto-appended streaks) is uncommitted — fold into next real commit.

New capabilities shipped this session:
- `check-staleness.sh <run-dir>` + per-row skill/def/env identity hashes + `run.sh --changed-only <baseline>` (ticket 33)
- `run.sh --judge-only <run-dir>` + `interchange.sh export|import` (ticket 32)
- `tkt batch <slug[:title]>... ` — N ids, one commit, group renumber (ticket 46)
- CREW_ENV policy gates across init/doctor/harnesses (ticket 36)

## Next Steps
1. **Monday triage: ticket 34 decision** — read `.scratch/session-review-spike-digest.md` (hit rates: P1 precision 1/2 with a known recall gap; P2 3/6 with fixable FP classes; cost envelope comfortable). Decide build/defer/fold-into-session-analysis; ACs 2-4 remain open on the ticket
2. Next-week set: 31 (crush/Bedrock — needs your AWS profile/region call), 35 (judge shadow study — needs budget nod; use `--judge-only` now that it exists), 39 (Windows session), 30 (personal machine)
3. Small follow-up worth a ticket: port `skill_usage.py::user_prompts()` to Prompt-line parsing — it matches ~nothing on the current transcript format (317/319 sessions have no USER MESSAGE BEGIN wrappers). Compliance counters are unaffected (raw-text scan, verified), but any future consumer of user_prompts() silently undercounts

## Fog
- Ticket 34 recall gap: keyword-free corrections (discovery-phrased rework orders) escape the P1 filter — the weekly LLM full-pass sketch in the digest is unvalidated
- 23's compliance ceiling: how much of the 65% non-compliance is legitimate skip conditions is unmeasured (denominator refinement candidate)

## Recommended Updates
- [ ] New ticket: user_prompts() format port (above)
- [ ] Consider folding spike prefilter into tools/session-analyzer/ if 34 lands as "build"
- [ ] Carried from 07-22: delete `.scratch/archwright-digest-tkt.md` on next cleanup

## Evidence
- Tickets 23/32/33/36/46 Resolutions carry per-AC evidence (all closed with --note); plan rows current; sync-plan pass
- Conformance highlights: 33 — skill/fixture/adapter edits each flipped exactly their drift kind; 32 — rejudge reproduced 3.83 FAIL from retained outputs, judge sets ["kiro"] vs [] under different availability, tamper rejection exit 1; 36 — planted agy manifest fired doctor violation, corp deploy unchanged; 46 — race hook renumbered whole group in one verified commit
- Spike artifacts: `.scratch/spike-34/` (prefilter.py + excerpts + 3 subagent verdict files), digest at `.scratch/session-review-spike-digest.md`
