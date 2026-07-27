---
id: "64"
title: "Research: sync-plan --fix for status-only plan drift (R9 report-only decision weighed first)"
status: done
blocked_by: []
env: either
spec: "ticket-cli"
---

# Research: sync-plan --fix for status-only plan drift (R9 report-only decision weighed first)

## What to build

**Research and a recommendation, NOT an implementation.** Decide whether `tkt sync-plan`
should gain a `--fix` mode that rewrites the STATUS CELL of drifted plan rows (and
optionally appends missing rows for open tickets), or whether report-only remains
correct.

Deliverable: a decision recorded in `.memory/specs/ticket-cli-spec.md` (accept → new
requirement id with scope; reject → rejected-alternative entry with revisit triggers),
plus a follow-up implementation ticket ONLY if accepted.

## Why now

Plan-row editing recurred in 3 consecutive sessions (guidance-sync P4, 2026-07-25 and
2026-07-27): each ticket close is followed by a hand-written python one-liner that
rewrites one plan row. Volume this session alone: 3 rows + 2 added rows.

## The tension to resolve (do not skip)

- **R9 chose report-only deliberately** (`.memory/specs/ticket-cli-spec.md`; exit
  contract 0=clean/1=drift/2=crash). sync-plan is the DRIFT DETECTOR — a tool that
  both detects and silently repairs drift can mask a real disagreement between the
  plan's narrative and ticket state.
- **Counter-pressure:** the repetitive edit is mechanical for the STATUS cell only
  (`open` ↔ `✅ done`), and hand-editing plan prose in a python heredoc is exactly the
  bulk-edit shape `surgical-git-side-effects` exists to discourage.
- **Asymmetry worth researching:** the status cell is derivable from ticket state; the
  narrative summary in the same row is NOT (it's human/agent authorship). Any `--fix`
  must not touch narrative text.

## Research questions

1. Prior art: how do drift-detection tools that gained a fix mode scope it (terraform
   apply vs plan, prettier --write, eslint --fix, ruff --fix)? What guardrails do they
   attach (dry-run default, explicit flag, unsafe-fix separation)?
2. Do any of them separate "safe/derivable" from "unsafe/authored" fixes, and how is
   that boundary declared?
3. What is the failure mode when a fix mode masks a genuine disagreement — documented
   incidents, not speculation?
4. Does the missing-plan-row case (currently a warning) belong in the same mode, given
   a new row needs a narrative cell no tool can author?

## Acceptance criteria

- [ ] Research findings recorded with sources (dispatch subagents per the research
      gates; ≥2 independent sources per question)
- [ ] R9's report-only rationale quoted from the spec and explicitly weighed — accept
      or reject stated against it, not around it
- [ ] Recommendation presented WITH findings (reasoning-only proposals are drafts, per
      the AGENTS.md Design Gate research rule)
- [ ] Decision recorded in `.memory/specs/ticket-cli-spec.md` (new requirement id, or
      rejected-alternative + revisit triggers)
- [ ] If accepted: implementation ticket filed with scope limited to derivable cells

## Out of scope

- Implementing `--fix` in this ticket
- Any mode that rewrites plan narrative text

## Resolution (2026-07-27)

ACCEPTED with Ruff-model scoping. Decision recorded as R9a in ticket-cli-spec.md. Implementation ticket: 66.
