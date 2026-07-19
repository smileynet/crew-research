---
id: "36"
title: "Environment designation (CREW_ENV) + agy policy enforcement on corp"
status: open
blocked_by: []
env: either
spec: ""
---

# Environment designation (CREW_ENV) + agy policy enforcement on corp

## What to build

Make the corp/personal environment split mechanical: a machine-local flag that tooling consults, and hard enforcement that agy can never deploy or run on corp (company policy — not an access limitation).

## Context

- **Policy (user, 2026-07-19):** agy violates company policy on the corp machine — expressly avoided and removed. It remains fully allowed in the personal environment; the repo stays multi-tool.
- **Already done on corp (2026-07-19):** agy artifacts removed (`~/.gemini/` tree incl. deploy-managed AGENTS.md + antigravity-cli/, and `~/.agents/skills/.crew-skills-agy`); binary was never on PATH. Shared `~/.agents/skills/` content untouched (codex still owns it via its manifest).
- **Flag exists:** `.mise.local.toml` (gitignored, line 8 of .gitignore as `.mise.local.toml`) sets `CREW_ENV=corp` here; verified loading via `mise exec -- printenv CREW_ENV`. Personal machine should set `CREW_ENV=personal`.
- **Policy-block ≠ access-skip:** ticket 29's probes handle "tool has no access"; this is stronger — on corp, agy must not run EVEN IF someone installs it. Distinct reason strings ("policy-blocked (CREW_ENV=corp)" vs "no access") so reports never conflate them.

## Acceptance criteria

- [ ] `init.sh`: `--tool agy` with `CREW_ENV=corp` refuses with a policy message (hard error, not warning); unset CREW_ENV → proceed with a notice
- [ ] `doctor.sh`: on corp, flags any agy artifacts (~/.gemini presence, .crew-skills-agy) as policy violations
- [ ] Eval + proof harnesses: agy judge/agent legs are policy-blocked when `CREW_ENV=corp` (before any `command -v` or access probe), with the distinct reason string
- [ ] Docs: AGENTS.md + user-setup-guide document the CREW_ENV convention and per-env deploy commands (corp: `--tool kiro-cli --tool codex`; personal adds `--tool agy --tool crush`)
- [ ] Conformance: on this machine, an attempted agy deploy fails with the policy error; a kiro-cli+codex deploy succeeds unchanged

## Out of scope

- crush/Bedrock configuration (ticket 31)
- Generalizing to arbitrary policy rules (one flag, one banned tool — build no framework; rule-of-two)
