---
name: readme-writing
description: "Write and improve README files that orient readers and drive adoption. Use when creating, rewriting, or auditing a project README. Trigger: write a readme, improve the readme, README structure, quick start section, getting started guide, project introduction, onboarding documentation, README template."
metadata:
  type: reference
  invocation: both
  practice: null
---

# README Writing

Developers decide in ~7 seconds whether to stay or leave. The first screenful is a landing page.

## The Opening Line

One sentence: category + differentiator. Use the project's proper name in title case for the H1, not the repo slug.

- `# Crew Research` not `# crew-research`
- `# Teach Me` not `# teach-me`

Opening sentence examples:

- "A git-native ticket tracker where tasks are markdown files." (tkt)
- "An extremely fast Python linter and formatter, written in Rust." (ruff)
- "A simple terminal UI for git commands." (lazygit)

## Let Readers Self-Select

Don't tell people who should use this. Show what it does — name what it replaces, show the output (GIF/screenshot), solve a real task in 60 seconds, or name who's already using it. Readers recognize their own situation.

## Quick Start

State the promise, then deliver in 3-5 steps. Always show output.

```bash
# Get a working project in under 2 minutes:
cargo install tkt
tkt new auth --title "Implement authentication"
tkt ready
# → Ready (1):
# →   01  Implement authentication
```

- Install command visible without scrolling (above line 30)
- 3-5 steps max — each produces a visible result
- Show expected output so readers verify success
- No prerequisites before quick start — those go in Installation

## Section Order

Readers evaluate top-down and stop when satisfied:

1. **Identity** — one sentence + differentiator
2. **Proof** — feature bullets, benchmark, screenshot, or GIF
3. **Quick start** — install + first command + output
4. **Usage** — common operations, configuration
5. **Installation** — exhaustive (every package manager)
6. **Community** — contributing, links
7. **License**

## Fit to Project Type

| Type | Emphasize | Skip |
|------|-----------|------|
| CLI tool | Commands/flags table, shell completion, piping examples | Architecture, deployment |
| Library | Import + minimal example, API link, compatibility | Infrastructure, config files |
| Framework | Core concepts, scaffold→hello world, ecosystem | Internal architecture |
| Application | Run locally, deploy, env vars, troubleshoot | Public API docs |

## Feature Lists

```markdown
- **~50ms reads** — tickets are local files, not API calls
- **Single binary** — no runtime dependencies beyond git
- **Race-safe** — concurrent sessions get unique IDs automatically
```

3-6 bullets. Concrete capabilities, not vague qualities ("fast", "easy", "modern"). Default to plain `- **Bold** — description`. Never emojis in the opening sentence.

## What Doesn't Belong

| Content | Where it goes |
|---------|--------------|
| Internal architecture | docs/architecture.md |
| Agent instructions | AGENTS.md |
| Detailed API reference | Generated docs (Rustdoc, JSDoc) |
| Changelog/roadmap | CHANGELOG.md, GitHub releases |
| Design philosophy | A blog post |
| Prerequisites | Inside Installation, not before the hook |

## Anti-Patterns

- **Wall of text before quick start** — reader left after paragraph two
- **Prerequisites above the fold** — show what it does first
- **Config-first / badge bloat / screenshots of code** — CLI first, badges minimal, code must be copyable
- **TODO sections** — write it or omit it

## References

- For per-repo findings and type-specific detail, read [references/patterns.md](references/patterns.md)
