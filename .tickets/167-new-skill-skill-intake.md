---
id: "167"
title: "NEW SKILL skill-intake: provenance-pinned external skill install (P2)"
status: open
blocked_by: []
spec: "rider-followups"
---

# NEW SKILL: skill-intake (provenance-pinned external skill install)

## Intent source

Rider review, skill-installer (whole-concept). Proposal:
`.scratch/new-skill-proposals-from-rider.md` P2. skill-installer's strengths: prose-orchestrates
+ hardened-script, defense-in-depth path validation, download→git→SSH fallback, idempotency.
Its documented GAP: no provenance — `--ref main` = non-reproducible, no pinned SHA, installs
executable instructions with no audit trail.

## Gap it fills

crew-research deploys skills (init.sh) and studies reference repos (study-reference,
adopt-project) but has NO skill for safely bringing an EXTERNAL skill/tool into a project. The
teach-me intake (ticket 158) did this ad hoc. A skill is executable instruction for the agent →
a drifting/compromised upstream is a supply-chain surface.

## What to build

A process skill `atomics/skills/skill-intake/SKILL.md`. Rules:
1. Pin to a resolved commit SHA — never a moving `main`.
2. Record provenance (`repo@sha` + timestamp) in the installed skill dir (e.g. a `.source` file).
3. Path-safety the copy (no `..`, no escaping symlinks, require a SKILL.md).
4. Idempotency guard (don't silently overwrite).
5. Confirm before installing from an untrusted (non-allowlisted) source.
Respect the 89/90 project-level precedent — this is the safe-intake PROTOCOL, not a global
auto-installer.

## Acceptance criteria

- [ ] `skill-intake/SKILL.md` authored, passes all skill-authoring Creation Gates
- [ ] Added to an appropriate composition (project-level per 89/90, likely)
- [ ] Activation eval: triggers on "install/vendor/adopt a skill from another repo", quiet on neighbors (study-reference, adopt-project)
- [ ] Behavior eval: with-skill pins a SHA + records provenance + path-safety, vs baseline
- [ ] `mise run validate` + `mise run lint` pass; generate clean

## Out of scope

- A global auto-installer (89/90: skill tooling stays project-level)
- Re-litigating 89/90

## Note

New skill → full evidence loop (activation + behavior eval) before trusted.
