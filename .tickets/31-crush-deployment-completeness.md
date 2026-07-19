---
id: "31"
title: "crush deployment complete on this machine: deploy, idempotency, docs; live probes deferred"
status: open
blocked_by: []
spec: ""
---

# crush deployment complete on this machine: deploy, idempotency, docs; live probes deferred

## What to build

Finish the crush deployment story that upstream 5a23e45 started: actually deploy on this machine, verify the deploy invariants, and document crush as a supported tool. Live behavioral probes (sentinel checks) defer to a machine with crush model access.

## Context

- **Upstream added the capability, not the deployment:** `deploy_crush()` exists (→ `~/.agents/skills/` + `~/.config/crush/AGENTS.md`), doctor has a crush check — but this machine has no `~/.config/crush/AGENTS.md` and no `.crew-skills-crush` manifest (verified 2026-07-19)
- **Shared-dir risk:** crush shares `~/.agents/skills/` with codex and agy — the per-tool manifest scheme (ticket 20) exists precisely because single-manifest prunes flap; a crush deploy must not perturb `.crew-skills-codex`/`.crew-skills-agy`
- **Deploy works without model access** (file placement only); what CANNOT be verified here is live skill loading — that's a sentinel probe owed to the deferred ledger (ticket 29)
- **Docs have zero crush coverage:** AGENTS.md multi-tool section, README deployment table, deploy-toolkit skill, user-setup-guide (all `grep -c crush` → 0)
- **Files:** `tools/generator/init.sh` (deploy_crush), `tools/generator/doctor.sh`, `AGENTS.md`, `README.md`, `.kiro/skills/deploy-toolkit/SKILL.md`, `.kiro/steering/user-setup-guide.md`

## Acceptance criteria

- [ ] `init.sh --global --tier full --tool crush` deploys; second run is `0 updated, 0 pruned` (idempotency invariant)
- [ ] `.crew-skills-crush` manifest exists; a follow-up codex/agy deploy shows `0 updated, 0 pruned` (no cross-tool flap)
- [ ] doctor reports crush healthy (or documents why partial)
- [ ] Docs updated: AGENTS.md, README table, deploy-toolkit skill, user-setup-guide with crush paths + verify command
- [ ] Live sentinel probe (skill actually loads in a crush session) registered as owed in the deferred-run ledger

## Out of scope

- crush model access on this machine
- Eval defs (tickets 29/30)
