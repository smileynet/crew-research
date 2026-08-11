---
id: "79"
title: "Explore: kiro-cli v3 session format, breaking changes, and adaptation needs"
status: done
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

- [x] Document all v3 breaking changes relevant to crew-research
- [x] Identify which crew-research components need adaptation (init.sh, doctor.sh, session-analysis, recall ingestion, skills, steering)
- [x] List new v3 capabilities that crew-research could leverage (hooks, new APIs)
- [x] Produce spike tickets for each adaptation needed (with blocked_by pointing here)
- [x] Findings written to `.scratch/research/kiro-v3-exploration.md`

## Resolution (2026-08-11)

Explored. v3 is Early Access (opt-in since 2.8.0). NO changes needed now — skills/steering/deploy all backward compatible. CRITICAL when v3 becomes default: recall + session-analysis need SQLite ingestion path (sessions move from JSONL to data.sqlite3). Medium: eval harness needs permissions.yaml (replaces --trust-all-tools), tool ID references should update to snake_case. Low: hooks could automate recall-prime but not essential. Findings: .scratch/research/kiro-v3-exploration.md. Follow-up tickets deferred until v3 default is announced — no point building adapters for an opt-in beta.
