---
id: "79"
title: "Explore: kiro-cli v3 session format, breaking changes, and adaptation needs"
status: open
blocked_by: []
---

# Explore: kiro-cli v3 session format, breaking changes, and adaptation needs

## What to build

Exploration spike: investigate kiro-cli v3 (`kiro-cli --v3`) to understand what changed and what crew-research needs to adapt.

### Research areas

1. **Session format** — how does v3 store/structure sessions differently? Does the transcript format change (affects recall ingestion, session-analysis)?
2. **Hook mechanism** — v3 introduces global hooks (`~/.kiro/hooks/*.json`). How do these interact with skills/steering? Can they replace or augment the current deploy model?
3. **Breaking changes** — what v2 behaviors no longer work? Agent config format changes? Tool dispatch differences?
4. **Skill/steering loading** — does v3 change how `.kiro/skills/` and `.kiro/steering/` are discovered or loaded? New frontmatter fields? Loading order?
5. **Subagent dispatch** — any changes to the subagent pipeline API (stages, roles, tool access)?
6. **Deploy impact** — does init.sh need v3-specific paths/formats? Can one deploy serve both v2 and v3 users?

### Method

- Read kiro-cli v3 docs/changelog (kiro.dev)
- Run `kiro-cli --v3 --version` and inspect session artifacts
- Compare v2 vs v3 session transcripts
- Test current deploy against v3 invocation
- Document findings in `.scratch/research/kiro-v3-exploration.md`

## Acceptance criteria

- [ ] Document all v3 breaking changes relevant to crew-research
- [ ] Identify which crew-research components need adaptation (init.sh, doctor.sh, session-analysis, recall ingestion, skills, steering)
- [ ] List new v3 capabilities that crew-research could leverage (hooks, new APIs)
- [ ] Produce spike tickets for each adaptation needed (with blocked_by pointing here)
- [ ] Findings written to `.scratch/research/kiro-v3-exploration.md`
