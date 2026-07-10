# Tool-Specific Subagent Limitations

Known concurrency limits and failure patterns per tool. Only validated observations are listed.

## kiro-cli

| Property | Value | Source |
|----------|-------|--------|
| Max concurrent subagents | 4 | kiro.dev official docs |
| DAG queuing | Yes — excess stages queue automatically | kiro.dev docs |
| Empty response on large prompts | Confirmed | Observed: 11% success on synthesis, 93% on file-read |
| Prompt size threshold | ~5-10K tokens inline causes failures | Inferred from file-read vs synthesis success rates |
| Subagent model | Inherits from agent config (or default) | kiro.dev docs |

**Validated failure pattern:** 11-stage file-reading dispatch (100% success) followed by 5-stage synthesis dispatch (20% success) in same session. Root cause: synthesis prompts were 5-10K tokens inline.

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
| Max concurrent subagents | **UNTESTED** | No data |
| Empty response pattern | **UNTESTED** | No data |
| Prompt size sensitivity | **UNTESTED** | No data |

## crush

| Property | Value | Source |
|----------|-------|--------|
| Subagent support | **UNTESTED** (unclear if native subagents exist) | No data |
| Max concurrent | **UNTESTED** | No data |
