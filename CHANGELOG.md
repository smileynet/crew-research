# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- Deploy skills to any tool — kiro-cli, Codex, Antigravity, and Crush all supported via `--tool` flag
- Cross-session memory — AI remembers past decisions and project context between sessions when `recall` CLI is installed
- Ticket-driven work — drop `.tickets/` files in your project and the AI picks up the next unblocked task automatically
- End-of-session recommendations — handoff suggests which docs, skills, or scripts need updating based on session findings
- New skills: ticket-planning, multi-agent-validation, project-winddown, spec-driven-development, architecture-deepening, feedback-loop-debugging
- Smarter design interrogation — parallel research, persistent findings, decisions written back to specs
- Small-model eval comparison framework for validating fast-model choices across providers
- Release tooling — `mise run release` automates changelog, tagging, and GitHub releases
- Cross-session memory works on Windows/WSL — auto-discovers projects, staleness hooks fire on shell open
- Skill catalog shows tier membership and filters by tier — `mise run catalog --tier basic`
- Doctor warns when personal files in `~/.kiro/steering/` would be lost on redeploy — symlink them to keep them
- See which skills actually activate in your own sessions — `mise run session:skills` reports activation and steering compliance from session logs
- Concurrent-session safety for tickets — creating a ticket now claims its ID (fetch before allocating, push promptly), with a reconciliation rule for collisions
- Windows Git Bash invocation rules — script-file pattern prevents PowerShell `$`-interpolation corrupting bash commands

### Changed

- Extensions auto-activate when prerequisites are detected — no separate install step needed
- 56 skills (down from 68) — each has a single clear job, less overlap
- Session start proposes the next action instead of asking what to do
- Session handoffs compress old phases to one-line summaries
- `~/.kiro/prompts/` no longer used — all workflows are skills now. Move custom prompts to `~/.kiro/skills/{name}/SKILL.md`.
- Always-on steering cost cut by more than half (812 → 387 lines) — more context budget left for your actual work
- Every skill fits a 100-line budget — deep detail moved to on-demand reference files that load only when needed

### Fixed

- Skills failing to activate in Antigravity 2.0
- Deployment tool crash on projects with complex skill files
- Cross-platform script issues on macOS/BSD
- Memory extension blocked by sandbox restrictions
- Broken and contradictory skill content repaired — placeholder one-liners filled in, cross-skill conflicts resolved
- `mise run doctor` and `mise run catalog` report current reality — stale tier lists and dead checks removed
- recall install docs point at `./tools/recall` — the PyPI "recall" package is an unrelated squatter

### Removed

- okf-bundle and the session-start prime hook — superseded by the recall extension
- troubleshooting-protocol skill — merged into feedback-loop-debugging (same trigger space, one clear owner)

## [0.1.0] - 2026-05-31

Initial release. Basic and full tier deployment to kiro-cli with 68 skills, eval harness, and project workspace conventions.
