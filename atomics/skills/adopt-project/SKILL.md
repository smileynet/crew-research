---
name: adopt-project
description: "Migrate a brownfield project to crew-research conventions. Inventories existing skills and steering, captures special instructions, deploys without losing customizations."
metadata:
  type: process
  invocation: user-only
  practice: null
---

# Adopt Project

Migrate an existing project to crew-research conventions without losing existing customizations.

## Phase 1: Inventory

Check for existing configuration:
- `.kiro/` — steering, skills, agents
- `AGENTS.md`, `CLAUDE.md`, or similar guidance files
- `CONVENTIONS.md`, `CONTRIBUTING.md`, `DEVELOPMENT.md`
- Existing session docs (`.scratch/`, `.memory/`)
- Any custom workflows (skills with `invocation: user-only`)
- `references/` (reference repo directories — note clone URLs if available)

Report what exists and what would be replaced or merged.

## Phase 2: Capture Special Instructions

For each existing file that crew-research would replace:
1. Extract project-specific rules not covered by standard skills
2. Capture custom verification commands, naming conventions, architectural constraints
3. Note existing skills that overlap with crew-research equivalents (/handoff, /grill-with-docs, etc.)
4. Identify unique workflows worth preserving
5. Check for any "always do X" or "never do Y" instructions
6. Surface non-obvious gotchas — runtime surprises, deployment quirks, things not documented
7. Identify conventions — local rules that deviate from standard practice (naming, file placement, workflow)

Write captured instructions to `.memory/project-specific-rules.md`.

## Phase 3: Recommend

**Important framing:** If skills are already deployed globally (`~/.kiro/`), the agent has full access to all skills in every project regardless of what's scaffolded locally. This recommendation is about what *workspace structure* to set up in this specific project — not about limiting capability.

Based on inventory:
- Recommend what to scaffold locally (`.memory/`, `.scratch/`, AGENTS.md, `.crew-config.yaml`)
- Identify any project-specific steering rules to add locally
- List which existing workflows to keep vs replace with crew-research equivalents
- Flag conflicts between existing conventions and crew-research defaults

State explicitly: "Your global skills remain active. This sets up project-specific workspace conventions."

Present recommendation and wait for approval before proceeding.

## Phase 4: Deploy

1. Back up existing `.kiro/` to `.kiro.bak/` (if it exists)
2. Run init with approved tier
3. Merge captured special instructions into:
   - `.kiro/steering/project-rules.md` (always-on rules)
   - `.kiro/skills/{name}/references/project-notes.md` (skill-specific context)
   - `.crew-config.yaml` (param overrides)
4. Preserve any unique workflows as skills in `.kiro/skills/`
5. Migrate existing CONTEXT.md / glossary content if present
6. Document any reference repos in AGENTS.md "References" section with clone commands

## Phase 5: Verify

- Confirm all preserved rules are accessible
- Run verification commands
- Check that no existing workflows were broken
- Report what changed and what was preserved

## Rules

- Never delete without backing up first
- Preserve ALL project-specific rules (even if they seem redundant)
- Ask before replacing any existing workflow with a crew-research equivalent
- Capture the "why" of existing conventions, not just the "what"
- If existing setup has instructions like "always run X before committing" — that becomes steering
