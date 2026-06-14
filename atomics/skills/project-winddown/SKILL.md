---
name: project-winddown
description: "Extract durable lessons from a project into a portable summary. Use when a project is ending, pausing, or reached a natural conclusion and you want to capture what was learned for future projects. Trigger: wind down, wrap up, lessons learned, project summary, extract learnings, archive project, what did we learn."
metadata:
  type: process
  invocation: user-only
---

# Project Winddown

Extract everything learned from a project into a durable, portable summary that benefits future work.

## Process

### 1. Confirm Scope

Infer defaults, don't interrogate. Only ask what you can't determine:

- **Project**: detect from AGENTS.md, README, or directory name
- **Output**: `summary/` at project root (default — portable, discoverable)
- **Audience**: future-you (default unless told otherwise)

Ask only:
- Full winddown or mid-project checkpoint?
- Emphasis areas? (or "all equally")
- Any grouping preference? (domain, JTBD, UX pattern, chronological)

Do NOT ask 4+ questions before starting. Propose defaults, proceed unless corrected.

### 2. Dispatch Research Subagents

Fan out subagents to review the project's artifacts in parallel:

| Subagent | Reviews | Extracts |
|----------|---------|----------|
| Decisions | `.memory/adr/`, `AGENTS.md`, `.crew-config.yaml` | Architecture choices, what worked, what didn't |
| Code | `src/`, `crates/`, `lib/` (structure, not every file) | Patterns adopted, abstractions that paid off, dead ends |
| Process | `.scratch/`, `.memory/`, handoffs, commit history | Workflow discoveries, methodology insights |
| Research | `docs/`, `.scratch/research/`, references used | Key findings, sources worth keeping, dead-end topics |
| Tooling | `tools/`, `mise.toml`, scripts, CI config | Tool choices, automation patterns, infra lessons |

Each subagent writes findings to a temp file. Do NOT provide them with conclusions — let them discover independently.

### 3. Synthesize

Combine subagent findings into `summary/` at project root:

```
summary/
├── README.md           — Overview + index of all docs
├── decisions.md        — Key decisions and their outcomes
├── patterns.md         — Reusable patterns discovered
├── dead-ends.md        — What was tried and abandoned (and why)
├── tools-and-setup.md  — Tooling choices worth reusing
└── methodology.md      — Process insights (planning, testing, collaboration)
```

Group by user need (JTBD) or domain when the project spans multiple areas. Adapt the structure to the project — don't force all projects into the same 6 files.

### 4. Quality Check

For each doc, verify:
- Could someone unfamiliar with the project extract value?
- Are lessons concrete (not "testing is important" — HOW did we test, what worked)?
- Are dead ends specific enough to prevent re-exploration?
- Are patterns extractable (could copy to another project)?

### 5. Present for Review

Show the user the README with the full index. Ask:
- Missing any major area?
- Anything to remove (too project-specific, not portable)?
- Any lessons that should become crew-research skills or steering?

## Rules

- Lessons must be portable — strip project-specific details unless they illustrate the point
- Dead ends are high-value — preventing future wasted effort is the primary goal
- Cite evidence (commit SHAs, file paths, dates) so lessons are traceable
- Keep each doc focused — one topic per file, link between them via README
- Don't summarize what the project IS — summarize what was LEARNED
