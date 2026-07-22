---
name: mcp-partitioning
description: "Partition MCP servers across a lean default agent and specialist agents to avoid tool bloat. Use when sessions feel slow or tool selection misfires, when adding an MCP server, when designing agent configs, or when validating that agents actually load their tools. Trigger: tool bloat, too many tools, mcp server placement, agent config, specialist agent, slim default session, tools whitelist."
metadata:
  type: reference
  invocation: both
  practice: null
  tools: [kiro-cli]
---

# MCP Partitioning

Keep the default agent lean; push specialist MCP servers into named agents. Tool-selection accuracy degrades past ~30–50 tools, and every server's schemas ride along in every request. A measured migration (2026-07): 9 global servers / ~230 tools → 2 servers / ~14 tools per default session, with specialists still reachable via agents.

## The Placement Rule

A new MCP server goes in a **specialist agent** unless you'd use it in most sessions regardless of task. Essentials (global config) are the 2–3 servers every session needs — typically internal search/docs + cloud APIs. Everything else maps to a domain agent (comms, CRM, ops, content...).

Specialists stay reachable from a lean session three ways: subagent dispatch (role = agent name), one-shot `--agent NAME --no-interactive` runs, or in-session agent swap.

## The Zero-Tools Trap (kiro-cli)

Agent configs that LOOK right can load **zero** MCP tools. Verified requirements (see [references/kiro-cli.md](references/kiro-cli.md) for the full config shape):

1. `tools` whitelist is mandatory: `["@builtin", "@<server>", ...]` — no whitelist, no tools
2. Global-config inheritance is **opt-in** (`useLegacyMcpJson: true`), not default
3. The whitelist gates inherited servers too — essentials must be listed even when inherited

Never trust a config by reading it. Validate with a live session probe.

## Validation Pattern

Three probes, all asking for exact sentinel words (LLM prose is not a check):

| Probe | Prompt shape | Proves |
|-------|-------------|--------|
| Positive (per agent) | "Call <tool>; if it succeeds reply exactly OK_SENTINEL" | Agent loads its servers |
| **Negative** (default agent) | "Call <specialist tool>; if unavailable reply exactly UNAVAILABLE_SENTINEL" | The partition is live — default can't reach specialists |
| Anti-vacuous drill | Deliberately violate (re-add a specialist to global), rerun | The checker itself can fail — a check proven only on passing cases may test nothing |

The negative probe is the critical one: without it, a botched trim passes silently.

## Config File Classes

Some tools atomically rewrite their config files (write-temp-then-rename), destroying any symlink pointing at them — kiro-cli does this to its settings file every session. For dotfile-managed configs:

- **Symlink-managed**: files only you edit — drift detection = link check
- **Content-managed**: files the tool rewrites — deploy by copy, detect drift by content diff. A symlink check here produces chronic false alarms that train you to ignore the real signal.

**Agent configs are content-managed** (observed 2026-07-22): on AIM-managed machines, AIM's credential-sandbox tooling rewrites `.kiro/agents/*.json` on load — appends `@creds-agent` to `tools` and `allowedTools`, adds a `creds-agent` entry to `mcpServers`, and reformats the JSON (Jackson style, no trailing newline). It appends rather than replaces, so hand-authored entries survive. Never symlink agent configs — AIM writes through the link back into your source repo.

## Deploy Semantics (team distribution)

When shipping agent configs as team defaults: copy-if-missing, skip-if-identical, and **never overwrite a differing file without an explicit force flag + backup** — users customize agents, and a silent clobber destroys their work.

On AIM-managed machines, skip-if-identical never matches after the target's first session (AIM churn, above). Drift checks must compare semantically — source entries present in the live file, ignoring `@creds-agent` additions and formatting — not byte-identical.
