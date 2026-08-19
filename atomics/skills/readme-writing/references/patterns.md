# README Patterns from Popular Projects

Research from 8 repos with 10K+ GitHub stars (ripgrep, bat, ruff, uv, vite, ollama, lazygit, gum). Studied 2026-08-18.

## Opening Lines That Work

| Repo | Opening | Pattern |
|------|---------|---------|
| ripgrep | "ripgrep recursively searches directories for a regex pattern while respecting your gitignore" | What it does + key differentiator |
| bat | "A cat(1) clone with syntax highlighting and Git integration" | Category + features |
| ruff | "An extremely fast Python linter and code formatter, written in Rust" | Category + speed claim |
| uv | "An extremely fast Python package and project manager, written in Rust" | Same pattern as ruff |
| vite | "Next Generation Frontend Tooling" | Aspirational tagline (less effective — too vague) |
| ollama | "Get up and running with large language models" | Action-oriented (what you'll do) |
| lazygit | "A simple terminal UI for git commands" | Category + simplicity claim |
| gum | "A tool for glamorous shell scripts" | Category + personality |

**Best performers:** concrete + differentiator beats aspirational.

## How They Prove Value (first screen)

- **Benchmarks:** ripgrep (speed table), ruff ("10-100x faster" + graph)
- **Screenshots/GIFs:** bat (syntax highlighting), lazygit (UI), gum (demo script)
- **Feature bullets:** uv (emoji list), vite (emoji list)
- **Demo video:** ollama (terminal recording)

Rule: proof comes immediately after the opening line, before explanation.

## Quick Start Patterns

| Type | Example | Best for |
|------|---------|----------|
| One-liner | `curl -fsSL ... \| sh && ollama run llama3.2` | CLI tools |
| Install + run | `brew install bat` then `bat README.md` | Tools with output |
| Tutorial | gum's commit helper walkthrough | Interactive tools |
| Code snippet | FastAPI's 5-line server | Libraries |

Common thread: all show output or result, not just commands.

## What Popular READMEs Don't Include

Confirmed absent from all 8 repos studied:

1. JTBD tables or persona descriptions
2. "Motivation" or "Philosophy" sections at the top
3. Architecture diagrams
4. Changelog content (they link to CHANGELOG.md)
5. Roadmap / "planned features"
6. Prerequisites before the hook
7. "Feature comparison" tables against competitors
8. Verbose "About" section (the opening line IS the about)
9. Config-file-first setup instructions
10. "Getting Help" above the fold
