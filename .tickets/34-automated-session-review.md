---
id: "34"
title: "Explore: automated periodic session-history review for self-improvement opportunities"
status: open
blocked_by: []
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

## Acceptance criteria (exploration — findings over features)

- [ ] Spike verdict: can P1 (corrections) and P2 (friction) signals be detected from archived JSONLs with acceptable precision on a sampled window? (pattern-match candidates + LLM confirmation on a sample; report hit rates)
- [ ] Routing design: how a finding maps to project-local vs crew-research-global, and what artifact each produces (local: proposal file/ticket in that repo; global: crew-research ticket)
- [ ] Scheduling design: where it hooks (recall ingest cron? separate mise task? staleness-hook style?) and its cost envelope
- [ ] Recommendation: build/defer/fold-into-session-analysis, with evidence

## Out of scope

- Building the full pipeline before the spike verdict
- Auto-APPLYING changes (proposals only — a human approves, same as /guidance-sync)
- Non-kiro session formats (codex/agy/crush logs) — note feasibility, don't implement
