---
created_at: 2026-07-18T21:46:00+00:00
base_commit: 6f03640
handoff_key: post-baseline-frontier
---

# Handoff

## Objective
Frontier work continues: tickets 23 (recall-check compliance), 24 (activation detection cleanup), 26 (baseline refresh); 25 blocked by 24. All of 01-22 closed this session (13/14/15/16/19) — see docs/plan.md.

## Constraints
- Eval runs: setsid nohup + observe pattern ALWAYS (even dry-runs); never edit harness scripts mid-run; resume with `--skip-completed <dir>`, never hand-script
- ADR 0009 deploy semantics live now: steering refs → skills tree, links rewritten absolute; `~/.kiro/steering/references/` = user-owned only (environment-gotchas.md — never touch)
- Deploy idempotency invariant: second run must be `0 updated, 0 pruned` (see deploy-toolkit skill)
- Ticket IDs: `git fetch` + rescan before allocating (26 is max); push claims promptly
- kiro tool-use cancellation does NOT kill spawned processes — orphans survive and complete; kill by recorded exact PID only (two incidents this session)

## Prior Decisions
- ADR 0009: non-eager refs deploy adjacent to SKILL.md in the skills tree; AGENTS.md tools get same files, links rewritten (codex/agy were dangling). Per-tool manifests `.crew-skills-{tool}` — codex+agy SHARE ~/.agents/skills; single-manifest prune flaps
- Ticket 19: activation-recall RETIRED — recall-check steering owns the trigger space ("steering shadow", now in glossary); measurement moved to field compliance
- Ticket 14: feedback-loop failures were fixture-task mismatch (tasks described nonexistent bugs), NOT merge dilution; per-task `fixture:` override added to run.sh; pre-2026-07-18 history for that def non-comparable
- Eval-proven again (ticket 13): gates > suggestions; trigger vocabulary must cover eval task phrasings
- Project tooling skills convention: every tools/ script family has a .kiro/skills/ guide (eval-harness, session-analysis, deploy-toolkit)

## Current State
Clean boundary — nothing mid-flight. Working tree clean, all pushed (6f03640). Global deploys current on all three tools. docs/plan.md is authoritative for ticket status.

## Next Steps
1. Ticket 23 (start soon — measurement clock): restructure recall-check steering as a gate, then ≥1 week field window before measuring vs 21% baseline. Early signal: 2-day window shows 42/98 (~43%) — promising, not evidence (see session-analysis skill for window rules)
2. Ticket 24: tee agent output to `$workdir/.eval-output` in run-activation.sh (~line 88), clean dead markers in check-activation.sh, no-regression `--all` run (19/19)
3. Ticket 26: full suite refresh (~8-10h judged run) — expect ≥29/35; re-justify each remaining known gap
4. Ticket 25 after 24: mcp-partitioning activation + effectiveness defs

## Fog
- Ticket 23 target (>50%) is a guess — adjust with justification if the gate redesign lands differently
- t09 rec #2/#5 (planning-cycles overlap, multi-agent-validation re-measure) deliberately deferred to ~2026-08-17 — do NOT ticket before then

## Recommended Updates
- [ ] skill(tool-installation): 223 lines — split into SKILL.md + references/ if it bothers anyone (justified as lookup table for now)
- [ ] user steering references/environment-gotchas.md: suggest adding "kiro cancellation doesn't kill spawned processes" gotcha (user-owned file — their call)

## Evidence
- Ticket resolutions with per-hypothesis evidence: `.tickets/{13,14,15,16,19}-*.md` (19 has the causal probe pair; 14 has the fixture verification)
- Eval runs: architecture-deepening `results/2026-07-18T14-48-21Z` (activation) + judged pass; feedback-loop `results/2026-07-18T15-26-45Z` + `15-55-26Z` (both PASS)
- Tried & failed: em-dash-in-H1 detection hypothesis (ticket 19 — full marker matched; dead end); inline kill of backgrounded eval runs (use truncate-copy simulation instead, see ticket 15)
