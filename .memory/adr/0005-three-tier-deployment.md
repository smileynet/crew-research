# ADR 0005: Three-Tier Deployment Model

## Context

With 54+ skills, deploying everything globally pollutes the user's `~/.kiro/` with specialist skills (creative writing, prototyping, meta-skills) that most projects never use. This increases activation noise and wastes context on irrelevant skill descriptions.

## Decision

Three deployment tiers: basic (minimal global), full (complete lifecycle global), project-level (on-demand per-project).

- **basic** (~13 skills): session continuity, planning, building, shipping fundamentals
- **full** (~42 skills): everything for active development — research, architecture, docs, deployment
- **project-level** (~12 skills): creative, prototyping, meta — installed to `<project>/.kiro/skills/` when needed

The agent suggests project-level skills during init, adopt-project, and read-handoff based on detected project content.

## Why

- Keeps global space focused (only universally-needed skills)
- Specialist skills activate only in projects that need them
- No pre-configuration ceremony — agent recommends at point of need
- `mise run add-skill -- <name>` provides simple install path
