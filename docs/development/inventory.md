# Inventory: All Behavioral Artifacts Across Reference Repos

Raw inventory of skills, agents, prompts, steering, templates, practices, and related items across agent-crews, best_practices, and ai-references.

## agent-crews

### Agents (93 total)

**Deployed (.kiro/agents/) — 17 meta-crew agents:**
dispatcher, crew-builder-lead, crew-creator, crew-augmenter, crew-researcher, crew-maintenance-lead, crew-analyst, crew-doctor, crew-validator, crew-releaser, project-hygiene, crew-tooling-lead, meta-tester, meta-debugger, kiro-helper, verifier, editor

**Base library (base/agents/) — 76 reusable agent definitions across 12 crews:**

| Crew | Agents |
|------|--------|
| general | general-lead, planner, explorer, researcher, challenger, advisor, architect, builder, tester, committer, reviewer, advocate, linter, deployer |
| bug-fix | bugfix-lead, triager, investigator, practices-advisor, reproducer, fixer, verifier, documenter |
| research | research-lead, outliner, internal-researcher, external-researcher, writer, fact-checker, editor |
| infrastructure | infrastructure-lead, deploy-planner, infra-advisor, provisioner, monitor, security-reviewer, cleanup |
| content | content-lead, narrative-writer, content-researcher, tutorial-writer, content-reviewer, publisher |
| writing | writing-lead, doc-auditor, doc-architect, doc-writer, tutorial-author, doc-verifier |
| hygiene | hygiene-lead, doc-checker, deps-checker, structure-checker, link-checker, fix-verifier |
| onboarding | onboarding-lead, mapper, analyst, auditor, restorer, guide-writer |
| rust | rust-lead, rust-linter, rust-builder, rust-tester |
| crew-builder | crew-builder-lead, crew-creator, crew-augmenter, crew-researcher, kiro-helper |
| crew-maintenance | crew-maintenance-lead, crew-analyst, crew-doctor, crew-validator, crew-releaser, project-hygiene |
| crew-tooling | crew-tooling-lead, meta-tester, meta-debugger |

### Crews (12)
general, bug-fix, research, infrastructure, content, writing, hygiene, onboarding, rust, crew-builder, crew-maintenance, crew-tooling

### Skills (37 in .kiro/skills/, source in shared/skills/)

**Single-file skills:**
adversarial-review, ai-assisted-development, analyze-sessions, code-review, coding-principles, configure-fleet, contribution-conventions, create-crew, crew-structural-rules, diagnose-crew, manage-components, run-evals, situation-routing, socratic-teaching, spike-workflow, task-lifecycle, testing-patterns

**Directory skills (with SKILL.md):**
adr-authoring, agents-md-authoring, changelog-discipline, completion-protocol, diataxis-classification, diagrams, docs-audit, document-formats, eval-criteria, git-protocol, kiro-cli-schema, presentation-writing, readme-writing, session-review-patterns, troubleshooting-protocol, tutorial-authoring, verification-protocol, write-skill, writing-style

### Prompts (7)
crew-sheet, grill-with-docs, handoff, read-handoff, release, thunderdome, tune-crew

### Steering (19 files across 4 tiers)

**Universal (all agents):** workspace, completion, signaling, sanity, reliability, scripts
**Orchestrator:** narration, memory, notifications, decisions, task
**Worker:** verification, git, troubleshooting, search, writing
**Standalone:** delegate-specialists, conventions, ai-generation-hygiene, source-citations

### Components (16 in shared/components/)
changelog, completion, decisions, git, handoff, memory, narration, notifications, relay-protocol, sanity-gate, search, signaling, task-tracking, troubleshooting, verification, writing

### Templates (1)
handoff.md — standardized handoff artifact template

### Scripts (5)
validate-mermaid.sh, notify-slack.sh, notify-toast.sh, notify-discord.sh, cache-docs.sh

### Hooks (1)
spawn.sh

### Eval Config (1)
.crews/evals.yaml — 46 behavioral evaluations

---

## best_practices

### Practices (33 documented best practices)

**Writing & Style:** writing-style, commit-messages, pull-requests, source-citations, changelog, readme-writing, marp-presentations, marp-styling, presentation-writing, presentation-methodologies

**Research & Decisions:** architecture-decision-records, research-methodology, prior-art-surveys, systems-architecture, jobs-to-be-done

**Task Tracking & Workflow:** task-tracking, session-completion

**Agentic Development:** agents-md-authoring, slash-commands, skill-agent-design, agent-code-review, code-review, review-response, agent-prompting (vocabulary), agent-tool-design, autonomy-delegation, mcp-configuration, stack-aware-tooling

**Testing & Quality:** testing-philosophy, test-pyramids, evaluation-methodology

**Cross-Project Patterns:** project-configuration, documentation-as-code, operational-patterns, observability-patterns

### Skills (6 implementations)
adr-authoring, commit-pr-discipline, research-methodology, testing-guide, tutorial-authoring, writing-style

### Agents (2 implementations)
reviewer, researcher

### Commands (3 implementations)
review, research, adr

### Templates (6)
AGENTS.md, ADR_TEMPLATE.md, PULL_REQUEST_TEMPLATE.md, REFERENCE_PAGE_TEMPLATE.md, SPINE_MODULE_TEMPLATE.md, METHODOLOGY_SURVEY_TEMPLATE.md

### Research (40+ bpappa research docs + primary research)
Each practice has a companion "bpappa" (best practices as prior art) research doc tracing sources. Plus standalone research: beads-assessment, cli-vs-mcp case study, testing-philosophy-research, agent-instruction-research, etc.

### Eval System
scripts/eval-prompt-vocabulary.sh — tests 27 prompt vocabulary keywords across models (Claude, GPT-5.4), with LLM judge scoring. Results stored per-model with scores.csv.

---

## ai-references

### Collections (3 major external reference sets)

**matt-skills (~22 skills):**
Engineering: code-review, commit-messages, debugging, documentation, git-workflow, pair-programming, project-setup, refactoring, task-management, testing
Productivity: focus-management, meeting-facilitation, note-taking, time-management
Misc: cooking, fitness, language-learning, music-practice
Plus templates, guides, deprecated items

**indydevdan (~70 agents, ~20 skills, ~15 prompts, ~15 steering):**
Multi-tool agent configurations for Claude Code and Pi. Includes:
- Agents: architect, researcher, debugger, reviewer, planner, implementer, tester, documenter, and many domain-specific variants
- Skills: various development and workflow skills
- Prompts: system prompts and testable prompts
- Steering: CLAUDE.md and AGENTS.md files per-project
- Workflows: justfiles, slash commands for orchestration
- Cookbooks and companion docs

**nicobailon (~30 skills, ~25 steering, 8 protocol specs):**
- Skills: development, research, writing, and workflow skills
- Steering: per-project behavioral guidance
- Protocols: UCP (Universal Communication Protocol) specification documents
- Agent guidance templates and bootstrap patterns

### Insights Layer (~40 analysis docs)
20 category analyses + 20 detailed findings + author/priority views. Cross-cutting analysis of patterns across all reference authors.

---

## Summary Counts

| Category | agent-crews | best_practices | ai-references | Total |
|----------|-------------|----------------|---------------|-------|
| Agents | 93 | 2 | ~70 | ~165 |
| Skills | 37 | 6 | ~72 | ~115 |
| Prompts | 7 | 0 | ~15 | ~22 |
| Steering | 19 | 0 | ~40 | ~59 |
| Practices/Guides | 0 | 33 | ~25 | ~58 |
| Templates | 1 | 6 | ~10 | ~17 |
| Crews | 12 | 0 | 0 | 12 |
| Components | 16 | 0 | 0 | 16 |
| Commands | 0 | 3 | ~7 | ~10 |
| Protocols | 0 | 0 | 8 | 8 |
| Eval definitions | 46 | 27 | 0 | 73 |
| Research docs | 0 | 40+ | ~40 | ~80 |
