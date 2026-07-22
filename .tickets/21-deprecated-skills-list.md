---
id: "21"
title: "Deprecated-skills list drives cleanup of retired skill names"
status: done
blocked_by: []
spec: "t09-baseline-followups"
---

# Deprecated-skills list drives cleanup of retired skill names

## What to build

A `compositions/deprecated.yaml` manifest of retired skill names. Deploy prunes deprecated dirs from `~/.kiro/skills/` even when the ownership manifest doesn't know them (pre-manifest machines); lint prevents a deprecated name from being reintroduced; doctor reports deprecated dirs found.

## Context

- **Gap:** ticket 20's manifest prune is warn-only for unmanaged dirs. Machines that deployed before the manifest existed carry stale crew-research skills (e.g., `troubleshooting-protocol`, the 12-skill consolidation set) as permanent "unmanaged" warnings with no cleanup path.
- **Known dead names (git history):** troubleshooting-protocol (5cd6bb5, merged into feedback-loop-debugging), assumption-tracking, commit-pr-discipline, completion-protocol, diataxis-classification, document-formats, five-whys, prompt-vocabulary, reference-exploration, research-dispatch, research-topics, session-review-patterns, situation-routing, spec-review (0304fe0 consolidation), image-analysis (6dec0ad → image-handling steering), windows-shell-safety (921eb2c → progressive reference).
- **Prune precedence:** symlink → keep · in tier → keep · deprecated → prune (with reason) · in manifest but left tier → prune · else → warn.
- **Safety:** symlinks are never pruned even for deprecated names (a symlink is someone's live source).

## Acceptance criteria

- [x] `compositions/deprecated.yaml` exists with the 16 known names + reason/replaced_by + since version
- [x] init.sh prunes a deprecated regular dir with the reason shown; symlinked deprecated name is kept
- [x] lint fails if a deprecated name exists in atomics/skills/ or any tier/composition
- [x] doctor reports deprecated dirs present in ~/.kiro/skills/
- [ ] Negative tests for prune (deprecated dir removed) and lint (resurrected name fails)

## Resolution
**Closed:** 2026-07-18 (Resolution backfilled 2026-07-22). `compositions/deprecated.yaml` (16 retired names with replaced_by/reason/since) wired into init.sh prune (symlinks kept via the `-L` guard), lint resurrection block, and doctor deprecated-dir reporting; retirement rule added to AGENTS.md. Evidence: docs/plan.md row 21 ("✅ done (2026-07-18) — compositions/deprecated.yaml (16 names) wired into init prune, lint, doctor"); closing commit d02d080 (diff shows prune-with-reason in init.sh, resurrection check in check-crosslinks.sh, deprecated-dir warning in doctor.sh).
Closed pre-tkt; unchecked ACs were not individually verified at close.
