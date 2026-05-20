---
created_at: 2026-05-20T06:42:00-07:00
base_commit: 4b0db2d
---

# Research: Prompt-with-Arguments Alternatives for Non-Interactive Testing

## Problem
`$ARGUMENTS` substitution is TUI-only in kiro-cli. How do we test skills that expect user-provided context (file paths, descriptions, parameters) in non-interactive mode?

## Findings

### What DOESN'T work in non-interactive mode
- `@prompt-name args` — trailing text after `@prompt` is lost (not passed as arguments)
- `$ARGUMENTS` / `${N}` — literal string, not substituted
- `/skill-name args` — slash commands don't work in non-interactive mode

### What DOES work in non-interactive mode

**1. Natural language query with skill activation (RECOMMENDED)**
```bash
kiro-cli chat --no-interactive -a "Diagnose this: my API returns 500 when payload exceeds 1MB"
```
The skill's `description` triggers activation, and the user's query IS the argument. The skill protocol shapes the response. This is how real users interact anyway.

**2. Inline prompt reference in natural language**
```bash
kiro-cli chat --no-interactive -a "Use @greet to say hello to Sam"
```
The agent reads the prompt file and applies it to the context. Works but less reliable than description-based activation.

**3. Direct query to a specific agent**
```bash
kiro-cli chat --no-interactive -a --agent researcher "Research testing patterns for Godot projects"
```
Agent-specific invocation with the task as the query. No skill activation needed — the agent's prompt + skills handle it.

## Implications for Eval Harness

The eval harness should test skills the way users actually use them:

| What to test | Method | Example |
|-------------|--------|---------|
| Skill activates for matching query | Natural language query | "Diagnose this bug..." |
| Skill doesn't activate for unrelated query | Unrelated query + check absence | "What is 2+2?" |
| Skill shapes behavior (protocol followed) | Natural language + canary/criteria check | Check output follows protocol steps |
| User-only skill works when invoked | `@prompt-name` (no args needed) | `@handoff` |
| Arguments reach the agent | Embed in natural language query | "Review src/main.rs for bugs" |

## Key Insight

**Arguments are the user's query itself.** In the non-interactive model, there's no separate "invoke skill + pass args" step. The user says what they want, the skill activates based on description match, and the user's full query provides the context. This is actually MORE realistic than `$ARGUMENTS` substitution — it tests the real user experience.

## Design Decision

For our eval definitions, the `input` field IS the argument:
```yaml
- name: diagnose-follows-protocol
  skill: diagnose
  input: "Diagnose this: my API returns 500 when the payload exceeds 1MB"
  criteria: |
    PRIMARY: Response follows the 3-hypothesis protocol before suggesting fixes.
```

No special argument handling needed. The harness passes `input` as the query, skill activates via description, and the criteria validate the behavior.
