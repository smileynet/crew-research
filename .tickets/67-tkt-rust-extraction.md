---
id: "67"
title: "Explore: extract tkt to own repo and rebuild in Rust"
status: open
blocked_by: []
priority: high
---

# Explore: extract tkt to own repo and rebuild in Rust

## What to build

**Exploration ticket — deliverable is a decision, not an implementation.**

Evaluate extracting `tools/tkt/` from crew-research into its own repository, rebuilt
in Rust. tkt is the most independent tool (zero content coupling) and the simplest
(no ML, no embeddings — just YAML parsing, dependency graphs, and git operations).
This makes it the ideal first extraction: proves the pattern, validates the toolchain,
establishes the cross-platform distribution story.

## Research (completed 2026-07-28)

Findings in `.scratch/research/`:
- `rust-vs-go-cli.md` — Rust recommended for full suite (embedding story)
- `tkt-rebuild-architecture.md` — architecture patterns, git integration, prior art
- `monorepo-decomposition.md` — when to split, failure modes
- `jtbd-decomposition.md` — separability test (tkt passes cleanly)

## Questions to answer

1. **Contract preservation:** Can the Rust CLI maintain 100% CLI compatibility with the
   Python tkt? (same commands, same flags, same output format, same exit codes)
2. **Migration path:** Can users switch from Python tkt to Rust tkt with zero friction?
   (install new binary, remove old — no config migration, no data migration)
3. **Architecture decisions:**
   - clap derive for CLI parsing (validated in research)
   - Shell out to git binary for v1 (matches gh CLI pattern, full auth compat)
   - serde + yaml-front-matter for frontmatter parsing
   - In-memory dependency graph (topological sort)
4. **Distribution:** cargo-binstall + GitHub releases + brew tap?
5. **Test strategy:** Port the 48 Python tests to Rust integration tests? Or keep a
   compatibility test that runs both CLIs against the same fixtures?
6. **Session review:** What does actual tkt usage look like? Run `session:skills` to
   identify which commands are used, which are never used, and whether the contract
   has vestigial features.

## Acceptance criteria

- [ ] Decision: extract to own repo YES/NO (with reasoning)
- [ ] Decision: Rust YES/NO (with reasoning — could be "Go for tkt, Rust for recall")
- [ ] Architecture sketch: modules, dependencies, test strategy
- [ ] Distribution plan: install methods per platform
- [ ] Migration plan: how existing users switch (zero-friction requirement)
- [ ] Session usage audit: which tkt commands are actually used in practice
- [ ] If YES: repo created, scaffold committed, README with plan

## Out of scope

- Full implementation (that's the follow-up after this exploration)
- Changing tkt's contract (the rebuild preserves the existing interface)
