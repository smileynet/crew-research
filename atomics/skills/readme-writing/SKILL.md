---
name: readme-writing
description: "Write and improve README files that orient readers and drive adoption. Use when creating, rewriting, or auditing a project README. Trigger: write a readme, improve the readme, README structure, quick start section, getting started guide, project introduction, onboarding documentation, README template."
metadata:
  type: reference
  invocation: both
  practice: null
---

# README Writing

The README is the front door. Most people decide whether to use a project in the first 10 seconds of reading it.

## The Opening Line

One sentence that names what it IS and what makes it different:

- "A tool for glamorous shell scripts." (gum)
- "An extremely fast Python linter and formatter, written in Rust." (ruff)
- "A simple terminal UI for git commands." (lazygit)

Pattern: `A [category] that [differentiator].` Write what it does, not how it works.

## Let Readers Self-Select

Don't tell people who should use this. Show what it does and trust them to decide:

| Strategy | Example |
|----------|---------|
| Name what it replaces | "Drop-in replacement for grep, 10x faster" |
| Show the output | Screenshot, GIF, or terminal recording |
| Solve a real task | Tutorial that builds something useful in 60 seconds |
| Name who's using it | "Used by FastAPI, Airflow, pandas..." |

Readers recognize their own situation. They don't need a table explaining personas.

## Quick Start: Speed to First Value

Install → run → see output. Under 30 seconds. No theory, no background, no prerequisites before the hook.

```bash
brew install myproject       # or: cargo install, pip install, curl
myproject init
myproject run example.md
# ✨ Output: 3 pages processed
```

Show expected output. Omitting a required step manufactures frustration.

## Section Order

Put decision-relevant content first. Readers evaluate top-down and stop when satisfied:

1. **Identity** — one sentence + differentiator
2. **Proof** — benchmark, screenshot, GIF, or feature bullets
3. **Features** — what can it do? (short list with examples)
4. **Getting started** — install + first command
5. **Usage** — common operations, configuration
6. **Community** — contributing, links, support
7. **License**

Not every project needs every section. Fit to the project, but don't invent a new order.

## Feature Lists

Emoji-bullet lists communicate capability at a glance:

```markdown
⚡️ 10-100x faster than existing tools
📦 Zero configuration needed
🔧 Drop-in replacement for X and Y
🪶 Single binary, no dependencies
```

3-6 bullets. Each one a concrete capability, not a vague quality.

## What Doesn't Belong

| Content | Where it goes |
|---------|--------------|
| Internal architecture | docs/architecture.md |
| Agent instructions | AGENTS.md |
| Detailed API reference | Generated docs |
| Changelog/roadmap | CHANGELOG.md, GitHub releases |
| Design philosophy | A blog post, not the README |
| Prerequisites | Inside the Installation section, not before the hook |

## Anti-Patterns

- **Wall of text before quick start** — reader left after paragraph two
- **Prerequisites above the fold** — "You'll need Node 18..." before showing what the tool does
- **TODO sections that never shipped** — write it or omit it
- **Config-first setup** — show the CLI command first, configuration comes after first use
- **Comparison tables** ("us ✅ them ❌") — let benchmarks and demos speak instead
- **Badge bloat** — twelve badges signaling decoration, not quality
- **Stale version numbers in prose** — "Install v1.2.3" when latest is 2.5.0

## References

- For detailed patterns from popular repos (ripgrep, bat, ruff, uv, vite, ollama, lazygit, gum), read [references/patterns.md](references/patterns.md)
