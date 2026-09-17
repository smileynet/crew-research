---
id: "156"
title: "Document which CLI harness to use for which model (+ auth/availability preconditions)"
status: backlog
blocked_by: []
priority: high
validation_criteria:
  - "A single reference table maps model family (Claude/Opus, Gemini, GPT/Codex, GLM, etc.) to the CLI harness(es) that can serve it, with the exact non-interactive invocation + permission-bypass flag for each"
  - "Each harness row states its auth/availability precondition and how to detect it BEFORE dispatch (so a reviewer isn't dispatched to a harness that will only return indeterminate)"
  - "dispatch-review / model-matrix guidance points at this table when choosing reviewers; the coordinator picks harnesses whose precondition passes"
tags: ["dispatch-review", "harness", "documentation"]
---

# Document which CLI harness to use for which model (+ auth/availability preconditions)

## Context

We have four review/agent harnesses (codex, opencode, claude/Claude Code, agy/Antigravity), each
able to serve some models, each with its own auth story. There is no single place that says "to
review with Opus, use harness X; to review with Gemini, use harness Y" — the mapping is scattered
across tickets #121 (opencode), #131 (codex model blocker), #36 (agy env policy), #126 (headless
harness path). A dispatch this session tried to run Opus + Gemini via opencode and BOTH returned
`indeterminate` on an opencode billing wall — a coverage gap that a precondition check would have
caught before dispatch. The same model is often reachable through more than one harness, so the
choice depends on which harness is authenticated/available on THIS machine, not on the model alone.

## Observed this session (evidence to fold in)

- **codex** (`codex exec --dangerously-bypass-approvals-and-sandbox`): worked, produced a verified
  ticketed review. (But #131 records it can be model-blocked on other machines — machine-specific.)
- **opencode** (`opencode run --auto -m <provider>/<model>`): all models returned
  `CreditsError: No payment method` — billing not set up → every leg indeterminate.
- **claude / Claude Code** (`claude -p <prompt> --model opus --permission-mode bypassPermissions`):
  installed but `Not logged in · Please run /login` → indeterminate until interactive login.
- **agy / Antigravity** (`agy -p <prompt> --model gemini-3.1-pro-high --dangerously-skip-permissions
  --print-timeout <dur>`): authenticated and working; served Gemini fine. NOTE #36: agy is
  policy-blocked on `CREW_ENV=corp` — this table must respect that (agy row = personal env only).

## What to build

- A reference table (likely in `dispatch-review/references/model-matrix.md` or `known-tools.yaml`,
  plus a pointer from tool-installation): model family → harness(es) that serve it → exact
  headless invocation + bypass flag → auth/availability precondition → detect command.
- A pre-dispatch precondition check the coordinator runs per chosen harness (auth probe / trivial
  print) so an un-authed harness is skipped-with-reason, not dispatched into an indeterminate.
- Respect `CREW_ENV=corp` (agy excluded) per #36.

## Acceptance criteria

- [ ] Model-family → harness → invocation → precondition table exists in one referenced place
- [ ] Each harness has a documented pre-dispatch detect/probe (auth + model availability)
- [ ] dispatch-review picks harnesses by passing precondition, degrades with reason otherwise
- [ ] Cross-references #121, #131, #36, #126 instead of duplicating them
