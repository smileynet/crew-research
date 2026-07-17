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

### Changed

- Extensions auto-activate when prerequisites are detected — no separate install step needed
- 56 skills (down from 68) — each has a single clear job, less overlap
- Session start proposes the next action instead of asking what to do
- Session handoffs compress old phases to one-line summaries
- `~/.kiro/prompts/` no longer used — all workflows are skills now. Move custom prompts to `~/.kiro/skills/{name}/SKILL.md`.

### Fixed

- Skills failing to activate in Antigravity 2.0
- Deployment tool crash on projects with complex skill files
- Cross-platform script issues on macOS/BSD
- Memory extension blocked by sandbox restrictions

## [0.1.0] - 2026-05-31

Initial release. Basic and full tier deployment to kiro-cli with 68 skills, eval harness, and project workspace conventions.
