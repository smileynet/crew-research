---
id: "31"
title: "crush deployment complete on this machine: deploy, idempotency, docs; live probes deferred"
status: done
blocked_by: []
env: corp
spec: ""
---

# crush deployment complete on this machine: deploy, idempotency, docs; live probes deferred

## What to build

Finish the crush deployment story that upstream 5a23e45 started: actually deploy on this machine, verify the deploy invariants, and document crush as a supported tool. Live behavioral probes (sentinel checks) defer to a machine with crush model access.

## Context

- **Upstream added the capability, not the deployment:** `deploy_crush()` exists (→ `~/.agents/skills/` + `~/.config/crush/AGENTS.md`), doctor has a crush check — but this machine has no `~/.config/crush/AGENTS.md` and no `.crew-skills-crush` manifest (verified 2026-07-19)
- **Shared-dir risk:** crush shares `~/.agents/skills/` with codex and agy — the per-tool manifest scheme (ticket 20) exists precisely because single-manifest prunes flap; a crush deploy must not perturb `.crew-skills-codex`/`.crew-skills-agy`
- **Corp crush access = AWS Bedrock (grill Q01, 2026-07-19):** crush officially supports Bedrock — auto-detects AWS creds, requires `AWS_REGION`/`AWS_PROFILE`, exposes the **Anthropic Claude family only** (haiku-4.5 through opus-4.8 confirmed in this account), **prompt caching disabled** (cost caveat for repeated-context loops). Source: charmbracelet-crush docs /advanced/amazon-bedrock. So live probes ARE possible on corp once configured — the sentinel probe moves from "deferred" to an AC here; only GLM/Z.AI-specific work stays personal
- **Verify credentials/profile choice before wiring:** which AWS profile/region to use for crush is a user decision (cost lands on that account)
- **Docs have zero crush coverage:** AGENTS.md multi-tool section, README deployment table, deploy-toolkit skill, user-setup-guide (all `grep -c crush` → 0)
- **Files:** `tools/generator/init.sh` (deploy_crush), `tools/generator/doctor.sh`, `AGENTS.md`, `README.md`, `.kiro/skills/deploy-toolkit/SKILL.md`, `.kiro/steering/user-setup-guide.md`

## Acceptance criteria

- [x] `init.sh --global --tier full --tool crush` deploys; second run is `0 updated, 0 pruned` (idempotency invariant)
- [x] `.crew-skills-crush` manifest exists; a follow-up codex/agy deploy shows `0 updated, 0 pruned` (no cross-tool flap)
- [x] doctor reports crush healthy (or documents why partial)
- [x] Docs updated: AGENTS.md, README table, deploy-toolkit skill, user-setup-guide with crush paths + verify command
- [x] Crush configured against Bedrock on corp (AWS_REGION/profile per user choice); live sentinel probe passes locally (no longer deferred); Bedrock model list + caching-disabled cost caveat documented in the deploy-toolkit or a references/ file

## Out of scope

- crush model access on this machine
- Eval defs (tickets 29/30)

## Resolution (2026-07-27)

Deployed + verified: init crush run1 '1 updated', run2 '0 updated 0 pruned' (idempotent); .crew-skills-crush manifest present; follow-up codex + crush redeploys both 0/0 (no cross-tool flap); doctor 'Global (crush): 39 skills, AGENTS.md present'. Live sentinel probe PASSED: crush run --model bedrock/us.anthropic.claude-haiku-4-5-20251001-v1:0 -> OK (account 563171622587/us-west-2 per operator choice). Gotcha documented: bedrock/ + us. inference-profile prefix required (bare model id fails). Docs: AGENTS.md, README (commands + table row), deploy-toolkit + references/crush-bedrock.md (model list, caching-disabled cost caveat), user-setup-guide corp deploy set.
