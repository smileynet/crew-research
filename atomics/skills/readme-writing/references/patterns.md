# README Patterns from Popular Projects

Research from 8 repos with 10K+ GitHub stars (ripgrep, bat, ruff, uv, vite, ollama, lazygit, gum). Studied 2026-08-18. Supplemented with quick start research (12 sources) and type-specific patterns (6 sources).

## The 7.4-Second Window

Average developer attention span on first README visit. The first screenful functions as a landing page. Projects that moved their install command from line 122 to line 30 saw 2.2-4x conversion lift. Comprehensive READMEs correlate with 4x higher engagement (stars, forks, traffic).

## Opening Lines That Work

| Repo | Opening | Why it works |
|------|---------|--------------|
| tkt | "A git-native ticket tracker where tasks are markdown files" | Category + mechanism (the differentiator) |
| ripgrep | "recursively searches directories for a regex while respecting your gitignore" | What it does + key behavior |
| ruff | "An extremely fast Python linter and formatter, written in Rust" | Category + speed + implementation |
| gum | "A tool for glamorous shell scripts" | Category + personality |
| lazygit | "A simple terminal UI for git commands" | Category + simplicity claim |
| ollama | "Get up and running with large language models" | Action-oriented (what you'll do) |

Best performers: concrete + differentiator beats aspirational ("Next Generation Tooling").

## Quick Start Research

**Optimal parameters:**
- Time to first value: under 5 minutes (GitHub content model: ~600 words)
- Step count: 3-5 numbered steps with mini-success moments
- Always show output (creates psychological momentum, enables verification)
- State the promise upfront: "In 2 minutes you'll [specific outcome]"
- Install command must be above line 30

**What kills quick starts:**
- Prerequisites before the hook (40% abandonment during setup when assets aren't inline)
- "See installation.md for details" instead of inline one-liner
- No expected output shown (reader can't verify success)
- Multi-step manual setup when a single command would work

## Type-Specific Sections (Priority Matrix)

| Section | CLI Tool | Library | Framework | Application |
|---------|----------|---------|-----------|-------------|
| Opening identity | ★★★ | ★★★ | ★★★ | ★★★ |
| Quick start | ★★★ | ★★★ | ★★★ | ★★★ |
| Commands/flags table | ★★★ | — | — | — |
| Import + example | — | ★★★ | ★★ | — |
| Core concepts | — | — | ★★★ | — |
| Run locally | — | — | — | ★★★ |
| Deploy/infra | — | — | — | ★★★ |
| API reference | — | ★★★ | ★★ | — |
| Shell completion | ★★ | — | — | — |
| Compatibility matrix | — | ★★ | ★★ | — |
| Ecosystem/plugins | — | — | ★★★ | — |
| Env vars/config | ★★ | — | ★ | ★★★ |
| Piping/scripting | ★★ | — | — | — |
| Troubleshooting | — | — | — | ★★★ |

## How They Prove Value (first screen)

- **Benchmarks:** ripgrep (speed table), ruff ("10-100x faster" + graph)
- **Screenshots/GIFs:** bat (syntax highlighting), lazygit (UI), gum (demo script)
- **Feature bullets:** uv (list), ruff (emoji list), tkt (bold-dash list)
- **Demo video:** ollama (terminal recording)

Rule: proof comes immediately after the opening line, before explanation.

## What Popular READMEs Don't Include

Confirmed absent from all 8 repos studied:
1. JTBD tables or persona descriptions
2. "Motivation" or "Philosophy" sections at the top
3. Architecture diagrams
4. Changelog content (they link to CHANGELOG.md)
5. Roadmap / "planned features"
6. Prerequisites before the hook
7. "Feature comparison" tables against competitors
8. Config-file-first setup instructions
9. Verbose "About" section (the opening line IS the about)
10. Screenshots of text/code (uncopiable, unparseable by AI)

## AI-Era Consideration

76% of developers use AI tools (2026). Plain H2 headings + fenced code blocks + standalone sections serve both human scanning and AI context extraction. Avoid screenshots of code — they can't be copied or parsed.
