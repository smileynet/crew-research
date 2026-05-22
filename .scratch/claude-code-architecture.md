---
created_at: 2026-05-21T20:29:00-07:00
base_commit: 83b17a2
---

# Claude Code Architecture Reference (v2.1.148)

## Context Delivery Mechanisms

| Mechanism | Scope | Loading | How to configure |
|-----------|-------|---------|-----------------|
| CLAUDE.md | All agents + subagents (except Explore/Plan) | Eager (session start) | Place file at project root or parent dirs |
| Skills (.claude/skills/) | All agents, project-wide | Lazy (description match) | Place SKILL.md in directory |
| Subagent `skills` field | Specific subagent only | Eager (preloaded at spawn) | List skill names in frontmatter |
| Subagent system prompt | Specific subagent only | Eager (always present) | Markdown body of agent file |

## Subagent Architecture

### What loads at startup (non-fork subagent):
1. System prompt (markdown body of agent definition)
2. Task message (delegation prompt from parent)
3. CLAUDE.md + memory hierarchy (all levels, except Explore/Plan skip this)
4. Git status snapshot (except Explore/Plan)
5. Preloaded skills (full content of skills listed in `skills` field)

### Key constraints:
- Subagents CANNOT spawn other subagents
- Subagents start with fresh context (no parent conversation history)
- Forks inherit full parent context (experimental, requires env var)
- Background subagents auto-deny permission prompts

### Skill scoping via `skills` field:
```yaml
---
name: api-developer
skills:
  - api-conventions
  - error-handling-patterns
---
```
- Full skill content injected at startup (not just description)
- Subagent can STILL invoke other skills via Skill tool during execution
- To prevent: omit `Skill` from `tools` or add to `disallowedTools`
- Cannot preload skills with `disable-model-invocation: true`

## Agent Definition Format

```yaml
---
name: identifier
description: When to delegate to this agent
tools: Read, Grep, Glob, Bash        # allowlist (inherits all if omitted)
disallowedTools: Write, Edit          # denylist
model: sonnet | opus | haiku | inherit | full-model-id
permissionMode: default | acceptEdits | auto | dontAsk | bypassPermissions | plan
maxTurns: 50
skills:
  - skill-name-to-preload
mcpServers:
  - server-name                       # reference existing
  - new-server:                       # inline definition
      type: stdio
      command: npx
      args: ["-y", "package"]
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
memory: user | project | local
background: true | false
effort: low | medium | high | xhigh | max
isolation: worktree
color: red | blue | green | yellow | purple | orange | pink | cyan
initialPrompt: "auto-submitted first turn"
---

System prompt body in markdown.
```

## Invocation Methods

| Method | Syntax | When to use |
|--------|--------|-------------|
| Automatic | Claude decides based on description | Default behavior |
| @-mention | `@"agent-name (agent)" task` | Guarantee specific agent |
| --agent flag | `claude --agent name` | Whole session as agent |
| Natural language | "Use the X agent to..." | Suggestion (Claude decides) |
| --print (headless) | `claude --print "query"` | Non-interactive/harness |

## Headless/Non-Interactive Mode

```bash
claude --print "query"                    # single query, print response
claude --print --agent name "query"       # with specific agent
claude -p "query"                         # short form
```

- No TUI, no interactive prompts
- Skills still activate via description matching
- CLAUDE.md still loads
- Subagents still work (Claude delegates automatically)

## Key Differences from kiro-cli

| Feature | kiro-cli | Claude Code |
|---------|----------|-------------|
| Agent format | JSON | Markdown with YAML frontmatter |
| Context binding | Per-agent `resources` field | Project-wide discovery |
| Eager context | `.kiro/steering/` (per-agent via resources) | `CLAUDE.md` (all agents) |
| Skill scoping | Per-agent via `skill://` in resources | Project-wide; `skills` field for preloading |
| Subagent spawning | `subagent` tool | Agent tool (auto or @-mention) |
| Non-interactive | `--no-interactive -a` | `--print` |
| User-only skills | `.kiro/prompts/` (separate) | `disable-model-invocation: true` on skill |
