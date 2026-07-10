# Tool-Specific Subagent Limitations

Known concurrency limits and failure patterns per tool. Only validated observations are listed.

## kiro-cli

| Property | Value | Source |
|----------|-------|--------|
| Max concurrent subagents | 4 (queues beyond) | kiro.dev official docs |
| DAG queuing | Yes — 6/6 stages completed when dispatched at once | Proof S1: PASS |
| Empty response on large prompts | **Steering prevents** — agent refuses to inline large data | Proof S2: steering followed correctly |
| Prompt size threshold | Not directly tested (agent avoids the pattern) | Proof S2: INCONCLUSIVE for raw threshold |
| Subagent model | Inherits from agent config (or default) | kiro.dev docs |

**S1 result:** Dispatched 6 parallel file-read stages → all 6 returned canary values. Queuing works transparently beyond the 4-concurrent limit.

**S2 result:** Agent read the `subagent-reliability` steering and refused to dispatch inline synthesis, doing it directly instead. The steering prevents the failure pattern rather than the agent hitting it.

## codex

| Property | Value | Source |
|----------|-------|--------|
| Max concurrent subagents | Unknown (no documented hard limit) | Not in official docs |
| Empty response pattern | Confirmed (community reports) | GitHub issue #68093, #9748 |
| Sandbox restrictions | bubblewrap blocks loopback (affects CLI tools in subagents) | Validated locally |

**Validated failure pattern:** Subagents in `workspace-write` sandbox cannot run CLI tools needing network (e.g., embedding models). Must use `danger-full-access` for tool-invoking subagents.

## agy

| Property | Value | Source |
|----------|-------|--------|
| Subagent support in --print mode | **NO** — single-turn text completion only | Proof S1: agy ignores dispatch instructions |
| Interactive subagents | Unknown — may work in interactive TUI mode | Not tested |

**Proof finding:** `agy --print` mode doesn't support subagent dispatch. The tool treats all prompts as single-turn completions. Subagent reliability guidance does NOT apply to agy in non-interactive mode.

## crush

| Property | Value | Source |
|----------|-------|--------|
| Subagent support | **NO** — no native subagent mechanism | Proof S1: empty output on dispatch request |

**Proof finding:** crush has no subagent dispatch capability. It's a single-agent tool. Subagent reliability guidance does NOT apply to crush.
