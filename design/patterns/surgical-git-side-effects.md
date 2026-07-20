---
kind: pattern
id: surgical-git-side-effects
name: "Surgical Git Side Effects: Touch Only the Ticket"
scale: verbs-interactions
confidence: "★★"
status: active
serves: [pf-concurrent-sessions-safe, pf-files-hand-editable]
context: [git-native-claim]
completed_by: []
resolves_into:
  - "constraint:stage-only-ticket-file"
---

# Surgical Git Side Effects: Touch Only the Ticket

## Problem

**Claim and close must commit and push from whatever working tree they find, but a real working tree is usually dirty with unrelated work.**

## Context

In the context of `git-native-claim`, this pattern addresses what a single tool-initiated commit may contain.

## Forces

- **Desire:** Sessions coordinate safely through pushed ticket state (pf-concurrent-sessions-safe).
- **Desire:** Operators trust the tool never to sweep unrelated changes into its commits (pf-files-hand-editable — trust extends from file content to repo state).
- **Constraint (hard):** Claims/closes happen mid-task; a dirty tree is the NORMAL case, and blocking on it would kill the tool's usefulness (git-coordination-medium + operator decision D2a).

## Evidence

- Operator decision D2a (resolve 2026-07-20): "Tool stages only the ticket file (`git add <file>`), commits regardless of other dirt" — chosen over refuse-on-dirty explicitly because "mid-task closes with a dirty tree are normal."
- Empirical precedent for the hazard class: eval-execution steering records a containment regression where a script running in the repo root leaked ~30 generated files into the repo, overwriting README.md (2026-07-15) — unscoped writes into a shared tree are a known, realized failure mode in this project's history.
- Mechanism: `git add <explicit-path>` + `git commit` (no `-a`, no `.`, no `-A`) is the only staging discipline whose blast radius is provably one file; anything pattern-based can race with concurrent edits to the index.
- Rejected alternative — refuse on dirty tree: safer-looking, but converts every mid-task close into a stash/commit detour, punishing the primary workflow to protect against a hazard explicit staging already eliminates.
- Prior art (2026-07-20, `.scratch/research/prior-art-git-coordination.md`): two independent categories converge — community/design-rationale consensus on bulk-staging dangers incl. git's own deliberate exclusion of untracked files from `commit -a` (SO 2009/2010), and shipped CI bot-commit tooling that path-restricts tool commits (git-auto-commit-action `file_pattern` 2019–; planetscale/ghcommit-action 2023; lint-staged ecosystem 2017). No contradicting source; this pattern is stricter than common practice in the safe direction.

## Therefore

**Tool commits stage exactly one path.** Every git commit tkt makes (new, claim, close) stages only the ticket file it created or edited, by explicit path — never `git add .`/`-A`/`commit -a`, never a second file. The commit message follows `chore(tickets): <verb> <id>` so tool commits are recognizable in history. Pre-existing staged changes are left staged and untouched (commit uses an explicit pathspec, not the index state).

## Consequences

- Plan-table edits can never ride along on a close commit — plan sync is necessarily a SEPARATE concern (feeds projection-vs-second-truth, ticket 41).
- One-commit-per-action produces chatty history (accepted: claim visibility is the point).
- Does NOT cover: push discipline for the operator's own work commits (git-protocol skill territory), or multi-ticket batch creation commits (R13, ticket 41 — may batch into one commit with all created files explicitly staged).

## Verification

- Constraint spec `stage-only-ticket-file`: tkt source contains no `git add .`, `git add -A`, or `commit -a` invocations; staging calls take an explicit single path variable.
- Acceptance test: claim/close in a deliberately dirty fixture tree commits exactly one file (diff-tree assertion).

## Completion

This pattern is incomplete unless it also contains:
- Nothing further — it is the leaf discipline under `git-native-claim`.
