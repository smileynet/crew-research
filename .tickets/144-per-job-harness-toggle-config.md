---
id: "144"
title: "User config to selectively enable/disable harnesses per job (eval, judge, review) — supersedes 142/143"
status: open
blocked_by: []
validation_criteria:
  - "a user-level config selects which tools/harnesses run for each job type (eval, judge, code review, ...), the eval/proof/dispatch-review harnesses read it and include/exclude legs accordingly, and an unavailable or disabled tool degrades a job as a reported gap rather than failing it"
tags: ["kiro-v3"]
---

# User config to selectively enable/disable harnesses per job (eval, judge, review)

## Intent source

Session review 2026-08-30. Tickets 142 (agy reviewer) and 143 (Claude Code reviewer)
each add a hard-coded reviewer leg to dispatch-review. That pattern doesn't scale —
every new tool × every job type (eval runner, judge panel, code review matrix, proof
legs, shadow execution) becomes bespoke branching, and machine-to-machine differences
(which tools are installed, which models a plan can serve — cf. ticket 131 codex
blocker) get hard-coded instead of configured. The general solution is a **user config
that declares, per job type, which tools/harnesses participate** — turning "add agy as
a reviewer" into a config entry rather than a code change.

## Supersession

This **supersedes 142 and 143**: once a per-job harness registry exists, adding
agy or Claude as a reviewer is a config edit, not a skill/script change. 142/143
should build their adapters in a form this framework can absorb (declarative entry,
not bespoke branching). If 144 is scheduled first, 142/143 collapse into config +
adapter-doc work. Decide sequencing at planning: framework-first (142/143 shrink) vs
prove-two-reviewers-first-then-generalize (142/143 inform the config schema).

## Scope of "jobs" (harness consumers to unify)

- **eval** — `tools/evals/harness/run.sh` (which tools' legs run; corp already
  excludes agy via CREW_ENV — see below)
- **judge** — judge panel membership (`meta.json` judges.live/excluded)
- **code review** — dispatch-review reviewer set + opencode matrix roster
  (`tools/proofs/adapters/opencode.yaml` → `dispatch_review.models`)
- **proof** — adapter proof legs (`tools/proofs/`)
- **shadow execution** — ticket 122 model comparison
- (extensible — the registry should not hard-enumerate consumers)

## Tension / design gate (archwright — likely YES on all three)

1. **Tension:** per-job granularity (fine control) vs config sprawl / duplication
   (every job re-declaring the same tool list). Naive per-job lists violate DRY;
   a single global list violates the per-job requirement.
2. **Durable invariant:** this config sits UNDER the existing **CREW_ENV policy**
   (corp forbids agy MECHANICALLY — init refuses, doctor flags, harnesses exclude
   with reason `policy-blocked`). A per-job toggle must NOT be able to re-enable a
   policy-blocked tool. Policy is a hard floor; user config is a softer layer on top.
   This guarantee must hold under hand-edits and future contributors.
3. **Rejected alternative to pre-empt:** "just use CREW_ENV / env vars per job" —
   env-only doesn't express per-job-type selection cleanly and doesn't survive as
   shared project config. Also pre-empt "one flag per harness script" (unmaintainable).

→ Any YES ⇒ propose an **archwright pipeline run before building** (per AGENTS.md
Design Gate). This ticket names the forces; the pipeline resolves the schema.
Prior art to research first (source-authority gates): how eval/proof harnesses
already gate legs by CREW_ENV; existing config layering (`.mise.local.toml`,
`.tickets/config.toml`, opencode.yaml rosters); recall of decisions on tool-set
gating (ticket 36 env-designation-agy-policy).

## Open design questions (resolve in pipeline, don't pre-decide)

- Where does the config live? (`~/.crew/config.*` user-level vs project `.mise.local.toml`
  vs a new `compositions/` file) and how does it layer (project > user > defaults,
  cf. spellbook ADR 0004)?
- Schema shape: `jobs.{eval,judge,review,...}.tools: [...]` with an inherit/default
  list? Enable-list vs disable-list (denylist composes better with the CREW_ENV floor)?
- How do harnesses consume it uniformly without each re-implementing parsing?
- Interaction with `matrix.sh --health` (probe only enabled legs) and with
  `coding-plan-limits` degrade semantics.

## What to build (post-pipeline)

1. A per-job harness/tool selection config with defined layering + a CREW_ENV
   policy floor that user config cannot override.
2. A single shared reader the harnesses use (eval, judge, dispatch-review, proof)
   to resolve "which legs run for job X on this machine".
3. Migrate dispatch-review's reviewer set (and, if 142/143 landed, agy/Claude) to
   registry entries.
4. Degrade semantics: disabled OR unavailable OR policy-blocked tool → reported gap
   for that job, never a hard failure; each with a DISTINCT reason
   (disabled / unavailable / policy-blocked).

## Acceptance criteria

- [ ] Config selects participating tools/harnesses per job type (eval, judge, review, + extensible)
- [ ] Documented layering (project > user > defaults) with a CREW_ENV policy floor user config CANNOT override (corp-agy stays blocked)
- [ ] eval, judge, dispatch-review (+ proof) read the config through ONE shared reader; no per-script re-implementation
- [ ] Disabled / unavailable / policy-blocked legs each degrade the job as a reported gap with a DISTINCT reason
- [ ] dispatch-review reviewer set (incl. any 142/143 additions) expressed as config entries, not hard-coded branches
- [ ] Design captured (archwright pipeline artifacts in design/ + gating checks, or an ADR if the pipeline is skipped with justification)

## Out of scope

- Adding specific reviewers (that's 142/143 — this is the mechanism they plug into)
- Changing CREW_ENV policy semantics (this layers under it, doesn't replace it)
