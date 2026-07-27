---
id: "34"
title: "Explore: automated periodic session-history review for self-improvement opportunities"
status: done
blocked_by: []
env: either
spec: ""
---

# Explore: automated periodic session-history review for self-improvement opportunities

## What to build

An exploration (spike first, tool second) of the automated counterpart to `/guidance-sync`: something that runs periodically, reviews session histories across projects, and surfaces self-improvement opportunities — routed to the right layer:

- **Project-local improvements** (a project's own `.kiro/skills/`, AGENTS.md, steering pointers, tools/ guides) — proposed against that project's repo, scoped by that project's session logs
- **Global improvements** (tier skills, steering, conventions) — ALWAYS routed through crew-research: proposals become crew-research tickets/PRs, never direct edits to deployed `~/.kiro/` files (deploys would clobber them; crew-research is the source of truth for everything global)

## Context

- **Manual counterpart shipped 2026-07-19:** `/guidance-sync` (P1 corrections, P2 friction, P3 new knowledge, P4 repetition, P5 coverage gate) mines the LIVE session; this ticket covers the archived-sessions variant it deliberately deferred
- **Existing substrate:** `tools/session-analyzer/` parses kiro-cli v2 JSONLs (per-session cwd metadata → project scoping already works — `sessions_per_project` in the report); recall ingestion (`ingest-all.sh`, 4h cron + staleness hooks) already touches every session periodically; `mise run session:skills` computes activation + compliance
- **Session→project mapping:** session JSONL `.json` sidecar carries `cwd` — the router key for project-local vs global proposals (a finding about a skill deployed FROM crew-research is global; a finding about a project's own tools/ is local)
- **Verified 2026-07-19:** session JSONLs don't embed injected steering text — probe heuristics match real conversation content
- **Cost consideration:** LLM-based probe passes over 100s of sessions are expensive — consider cheap heuristic prefilters (correction phrasings, error/retry bursts, repeated command shapes) that queue candidate sessions for LLM review, mirroring the P1–P4 probes
- **Deletion testing (from ticket 48 research, 2026-07-22):** the archived-sessions variant is the natural home for outcome-based prune evidence — a rule never involved in any correction across a window is a deletion candidate; a correction that recurs after a rule was removed argues restore-and-promote-to-hook. Research: `.scratch/research/agent-guidance-pruning.md` (regenerate if pruned)

## Acceptance criteria (exploration — findings over features)

- [x] Spike verdict: can P1 (corrections) and P2 (friction) signals be detected from archived JSONLs with acceptable precision on a sampled window? (pattern-match candidates + LLM confirmation on a sample; report hit rates) — 2026-07-25 YES: P1 2 candidates/316 sessions, precision 1/2, one keyword-free correction missed in 5-session FN probe (recall is the weak axis); P2 16 candidates, 3/6 sampled genuine (FP classes identified + fixable: fetched-doc tracebacks, log-noise repeats, deliberate probes). Digest: .scratch/session-review-spike-digest.md
- [x] Routing design: how a finding maps to project-local vs crew-research-global, and what artifact each produces (local: proposal file/ticket in that repo; global: crew-research ticket) — implemented: cwd sidecar -> project grouping in the digest; crew-research rows marked GLOBAL lane; documented in session_review.py docstring + digest header
- [x] Scheduling per grill Q03 (2026-07-19): MANUAL mise task first (also the spike vehicle, runs collect+synthesize end-to-end); architecture supports the future daily-collect (cheap heuristics -> candidate queue) / weekly-synthesize (batched LLM -> one deduped digest) pairing; cron graduation only after precision proves out. Artifact: digest file, human triages; the pipeline NEVER creates tickets — `mise run session:review [days]` shipped; collect is free, --confirm is the separable synthesize leg; digest-only output
- [x] Recommendation: build/defer/fold-into-session-analysis, with evidence — BUILD-as-fold decided by operator 2026-07-27 (spike evidence: precision workable at tiny volumes, cost trivial); landed as tools/session-analyzer/session_review.py

## Out of scope

- Building the full pipeline before the spike verdict
- Auto-APPLYING changes (proposals only — a human approves, same as /guidance-sync)
- Non-kiro session formats (codex/agy/crush logs) — note feasibility, don't implement

## Resolution (2026-07-27)

Built as fold into session-analyzer per operator decision. session_review.py: P1/P2 prefilter with spike-derived fixes (fetch-tool results skipped, distinct-line dedupe, discovery-phrased P1 patterns), cwd-based GLOBAL/local routing, optional --confirm via kiro-cli headless, digest-only output. Validation on live 7d window (234 sessions): both spike FP sessions (d0ea6ea6 fetched-doc tracebacks, 443c3e83 log noise) excluded; genuine friction retained; the spike's MISSED correction (c2befaf8) now detected AND LLM-confirmed GENUINE. mise run session:review [days] shipped; session-analysis skill documents it.
