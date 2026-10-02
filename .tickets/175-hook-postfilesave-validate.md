---
id: "175"
title: "Project PostFileSave hook — validate SKILL.md/compositions on save in crew-research repo"
status: in_progress
blocked_by: []
tags: [kiro-v3]
---

# Project PostFileSave hook — validate on save (crew-research repo only)

## What & why

Add a committed `.kiro/hooks/*.json` to the crew-research repo that runs the repo's
own validators when a `SKILL.md` or composition file is saved during an agent
session. crew-research dogfooding kiro-cli v3 hooks on itself — closes the
"verify-before-done" gap mechanically (on non-zero exit, stderr is returned to the
agent in-loop) instead of relying only on the `verification-protocol` steering.

**Non-gated / low-risk because:** it is a single file committed to THIS repo's
`.kiro/hooks/`, scoped by matcher to this repo's paths, referencing this repo's
`mise run validate`/`lint` tasks. It is NOT part of the user-facing global deploy
set (that is ticket 173/174), so it cannot run in unrelated user projects.

## Facts (from research, kiro.dev/docs/hooks)

- File: `.kiro/hooks/<id>.json`, `{"version":"v1","hooks":[...]}`, auto-discovered.
- `PostFileSave` trigger; `matcher` is a regex over the FILE PATH; `{{filePath}}` var available.
- command action: shell in project root, STDIN=event JSON, exit 0 → stdout to context,
  non-zero → stderr returned to agent as error. No credit cost. Set `timeout` explicitly.
- Hooks are v3; harmless/ignored on v2.

## What to build

- `.kiro/hooks/crew-validate-on-save.json` with two hooks:
  - matcher `SKILL\.md$` → `mise run validate`
  - matcher `compositions/.*\.(ya?ml)$` → `mise run lint`
- Explicit `timeout` (e.g. 120). Keep output short (`| tail -N`).

## Acceptance criteria

- [ ] `.kiro/hooks/crew-validate-on-save.json` committed, valid v1 schema (jq parses)
- [ ] Matchers target SKILL.md + compositions yaml only
- [ ] Commands call existing `mise run validate` / `mise run lint`; explicit timeout
- [ ] Does NOT enter the global deploy set (project-only; init.sh unchanged)
- [ ] Documented in AGENTS.md (dev-only hook) so contributors know it exists
