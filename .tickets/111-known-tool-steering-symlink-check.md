---
id: "111"
title: "Explore: doctor should verify known-tool steering is symlinked, not copied"
status: open
blocked_by: []
env: either
spec: "deploy-toolkit"
---

# Explore: doctor should verify known-tool steering is symlinked, not copied

## Problem

Self-deploying known tools that ship steering must symlink it into `~/.kiro/steering/`,
not copy it — crew-research's `init.sh` prune deletes unmanaged regular `.md` files there
on every deploy but preserves symlinks. A tool that copies has its steering silently
deleted on the next crew deploy, returning only when the tool re-deploys.

This has now happened twice:
- **tkt** copied `frontier-work.md` (its ticket 100 chose "copy, not symlink" without
  cross-checking crew's prune contract). Fixed in tkt ticket 110, 2026-08-18.
- **archwright** subagent-reliability collision (a fork overwriting crew's owned steering)
  — a related ownership-seam problem, noted in `compositions/known-tools.yaml`.

Detection today is partial and reactive:
- `doctor.sh` known-tool check inspects **skill** symlinks (found / broken) but never looks
  at the tool's **steering** files.
- The generic steering-prune warning (`⚠️ unmanaged steering file: X — next deploy will
  PRUNE it`) fires only AFTER a copy already landed, and only if someone runs doctor
  between the tool's deploy and the next crew deploy. Miss that window and the steering is
  just gone with no signal.

Prose guidance now documents the fix (deploy-toolkit skill, commit ccb86a5), but prose
that says "symlink your steering" is exactly the enforcement level that already failed
twice — the correction happened DESPITE the convention being written down.

## What to explore

Whether the rule-of-two threshold is now met to move from prose to mechanical detection,
and if so, the cheapest correct mechanism:

1. **Known-tool steering assertion in doctor.** For each tool in `known-tools.yaml` that
   declares steering, check every steering file it owns in `~/.kiro/steering/` is a
   symlink; warn (or fail) on a regular-file copy, naming the owning tool and the fix.
   Requires known-tools.yaml to declare which steering files a tool owns — it currently
   does not (only `skill_glob`). That schema addition is part of the spike.

2. **Alternative: leave detection to the existing generic warning** and instead invest in
   making the convention unmissable at the tool-author end (a shared deploy helper tools
   can source, or a documented `ln -sf` snippet in known-tools onboarding). Weigh against
   option 1 — the generic warning's timing gap is the core weakness.

3. Decide warn vs fail. The known-tool block is "pending-with-reason, never an error" by
   design (absence is not failure). A copied-steering file is different — it is an active
   misconfiguration that will lose data, not a benign absence. But failing doctor on
   another repo's deploy choice may be too aggressive; a loud persistent warning may be
   the right level.

## Acceptance criteria

- [ ] Decision recorded: mechanical check in doctor, tool-author-side helper, or
      keep-prose-only — with the rule-of-two reasoning (2 incidents) weighed explicitly
- [ ] If a doctor check is chosen: known-tools.yaml schema extended so a tool can declare
      its owned steering files; doctor asserts each is a symlink
- [ ] Warn-vs-fail decision recorded with rationale (data-loss misconfig vs another repo's
      choice)
- [ ] Whichever path: the archwright collision is re-checked against it — a fix that only
      catches tkt's copy but not archwright's overwrite is incomplete
- [ ] deploy-toolkit skill updated if the mechanism changes what a doctor warning means

## Out of scope

- Fixing tkt or archwright's deploy scripts (tkt done in its ticket 110; archwright is its
  own repo's concern)
- A parallel prune mechanism — detection only; the fix always lives in the owning tool
