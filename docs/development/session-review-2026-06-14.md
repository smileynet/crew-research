# Weekly Session Review: Jun 8–14, 2026

## Overview

| Metric | Value |
|--------|-------|
| Sessions | 50 |
| Total data | 109 MB |
| Projects active | 8 |
| Tool calls | 4,091 |

## Projects by Activity

| Project | Tool calls | Notes |
|---------|-----------|-------|
| crew-research | 1,038 | Eval development, skill authoring |
| rustacean-academy | 521 | Rust learning platform |
| pixelrig | 391 | Hardware/embedded |
| stash-ai | 281 | Media management AI |
| asset-production | 191 | GenAI game assets |
| catalyst_docs | 147 | Documentation |

## Tool Usage

| Tool | Count | % | Assessment |
|------|-------|---|------------|
| shell | 1,627 | 40% | ⚠️ HIGH — should be <25% |
| write | 827 | 20% | ✅ Good |
| read | 679 | 16% | ✅ Good |
| todo_list | 252 | 6% | ✅ Good |
| web_search | 225 | 5% | ✅ Good |
| grep | 120 | 3% | ⚠️ LOW — shell grep likely substituting |
| glob | 34 | <1% | ⚠️ LOW — shell find/ls likely substituting |

## Issues Identified

### 1. Shell Overuse (40% of tool calls)
**Severity:** Medium
**Pattern:** 627 `cd` commands (38% of shell calls) — agent navigating directories with `cd` instead of using `working_dir` parameter.
**Root cause:** tool-over-shell steering says "use working_dir" but doesn't explain the cd anti-pattern explicitly enough, or it's not activating in non-crew-research projects.
**Fix candidate:** Strengthen the `cd` prohibition in project-conventions steering. Add explicit: "NEVER prefix commands with cd. Use working_dir parameter."

### 2. Secrets in Shell Commands (78 instances)
**Severity:** High
**Pattern:** API keys (Sonarr, Prowlarr, Stash) passed as shell variables or inline in curl commands. JWT tokens visible in command history.
**Root cause:** Media management projects (stash-ai, torrent-stack) require API auth. Agent constructs curl commands with keys inline.
**Fix candidate:** Not a skill issue — these are necessary for the task. But the safety guardrail about not echoing secrets in responses should be verified. Consider a steering note about using env files for API keys.

### 3. Low grep/glob Usage (3% combined)
**Severity:** Low
**Pattern:** Agent likely using `shell` with `grep` and `find` commands instead of dedicated tools.
**Root cause:** When working on remote machines (SSH sessions — 106 commands), dedicated tools can't reach remote filesystems. For local work, may be habit or context where tool-over-shell steering isn't loaded.
**Fix candidate:** No fix for SSH use case (legitimate). For local work, verify tool-over-shell is in all deployed project steerings.

## Positive Signals

- **todo_list at 6%** — agent is tracking work consistently
- **web_search at 5%** — research is happening within budget
- **write at 20%** — using write tool over echo/heredocs
- **50 sessions in 7 days** — high utilization, no obvious session thrashing

## Recommendations

1. **Strengthen cd prohibition** — add to project-conventions: "NEVER use `cd` in shell commands. Use the `working_dir` parameter instead."
2. **Audit non-crew-research projects** — verify tool-over-shell steering is deployed to rustacean-academy, pixelrig, stash-ai
3. **No skill gaps detected** — current skills cover the observed workflows

## Comparison to Prior Review

| Metric | Jun 1 (prior) | Jun 14 (now) | Trend |
|--------|--------------|--------------|-------|
| Shell % | ~45% (est) | 40% | ↓ Improving |
| Dedicated tool usage | ~50% | 56% | ↑ Improving |
| Sessions/week | N/A | 50 | Baseline |
