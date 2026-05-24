---
title: "Phase 2 Results: Grounded Evals vs Empty-Workspace"
date: 2026-05-23
status: complete
depends_on: [eval-findings-v1, experiment-1-activation-results]
---

# Phase 2 Results: Grounded Evals

## Comparison: v1 (empty workspace) vs v2 (real project)

| Skill | v1 With | v1 Without | v1 Delta | v2 With | v2 Without | v2 Delta | v2 Status |
|-------|:-------:|:----------:|:--------:|:-------:|:----------:|:--------:|:---------:|
| eval-criteria | 5.00 | 2.33 | **+2.67** | 4.33 | 3.33 | **+1.00** | ✅ PASS |
| five-whys | 5.00 | 1.00 | **+4.00** | 2.66 | 4.00 | **-1.34** | ❌ FAIL |
| handoff | 5.00 | 3.00 | **+2.00** | 5.00 | 4.66 | **+0.34** | ❌ FAIL |
| situation-routing | 4.66 | 3.00 | **+1.66** | 5.00 | 4.33 | **+0.67** | ❌ FAIL |
| verification-protocol | 5.00 | 1.00 | **+4.00** | 3.66 | 1.00 | **+2.66** | ❌ FAIL* |

*verification-protocol fails on threshold (3.66 < 4.0) despite strong delta, and only activates 66% of the time.

## Key Findings

### F11: v1 results were inflated by empty-workspace conditions

In an empty workspace, agents have nothing to work with — they can't read code, run tests, or investigate. This artificially depresses the baseline (without-skill) score, making skills look more valuable than they are. In a real project, the baseline jumps from 1.0-3.0 to 3.33-4.66.

### F12: five-whys shows NEGATIVE delta in grounded context

This is the most surprising finding. In a real project, the agent naturally reads code and traces through logic. The five-whys skill's structured "Why 1 → Why 2 → Why 3" format actually **constrains** the agent's natural investigation, producing a worse result. The skill is optimized for explaining reasoning to humans, not for actually doing the investigation.

### F13: Most skills provide marginal value in realistic conditions

handoff (+0.34) and situation-routing (+0.67) show positive but small deltas. The agent already does these things reasonably well when it has real code context. The skills add polish but not transformative value.

### F14: eval-criteria is the only skill that clearly helps in both conditions

It's the only skill testing a behavior the agent genuinely doesn't know how to do well without instruction (structured eval criteria format). This suggests skills are most valuable for **novel formats/structures** the agent hasn't been trained on, not for **general reasoning patterns** it already exhibits.

### F15: verification-protocol has strong delta but activation problems

When it activates (66% of the time), it provides +2.66 delta — the agent genuinely runs tests more when told to. But it fails to activate on 1/3 of relevant tasks, and even when it does, the with-skill score (3.66) is below threshold. The skill helps but not enough.

## Implications

1. **v1 eval methodology was fundamentally flawed** — empty workspaces created artificial conditions that inflated skill value. All future evals should use real project fixtures.

2. **Skill value taxonomy needs revision**:
   - **High value**: Skills teaching novel formats/structures (eval-criteria)
   - **Moderate value**: Skills enforcing verification behaviors (verification-protocol) — but need eager loading
   - **Low value**: Skills teaching reasoning patterns the agent already does (five-whys, situation-routing)
   - **Negative value**: Skills that constrain natural investigation (five-whys in grounded context)

3. **The "less is more" hypothesis is confirmed** — SkillReducer's finding that skills can hurt applies here. five-whys literally makes the agent worse at diagnosis in a real codebase.

4. **Skill design principle**: Skills should teach behaviors the agent CAN'T do without them, not behaviors it already does. The test: if the baseline scores >4.0 without the skill, the skill isn't needed.

## Methodology Notes

- 1 trial per task (3 tasks per skill = 3 data points per condition)
- Fixture: unjs/defu (197 LOC TypeScript, 23 vitest tests)
- Timeout: 180s (needed for git clone + pnpm install + agent work)
- Activation verified via sqlite conversation data

## Revised: five-whys with Proper Diagnosis Tasks (v2)

The original grounded five-whys eval tested "trace through code" — which the agent does naturally. Revised eval tests actual diagnosis scenarios (non-obvious root causes, non-coding problems, recurring incidents).

| Metric | v1 (empty) | v2-original (code tracing) | v2-revised (diagnosis) |
|--------|:----------:|:--------------------------:|:----------------------:|
| With skill | 5.00 | 2.66 | 4.41 |
| Without skill | 1.00 | 4.00 | 3.66 |
| Delta | +4.00 | -1.34 | **+0.75** |
| Activation | 100% | 66% | 58% |

**Revised finding**: five-whys DOES help with diagnosis tasks (+0.75 delta), but the value is moderate, not transformative. The skill's value is in:
- Non-coding diagnosis (process problems, organizational issues)
- Problems with non-obvious root causes (recurring incidents)
- Situations where the agent would otherwise stop at the immediate cause

The skill does NOT help (and may hurt) when:
- The agent can just read the code to find the answer
- The problem is straightforward (one-step cause)
- The task is "explain this code" rather than "diagnose this problem"

**Threshold question**: Is +0.75 delta enough to justify the skill? The with-skill score (4.41) is above the quality threshold (4.0), meaning the skill produces good results. The delta threshold of 1.0 may be too aggressive for skills that improve already-decent baseline behavior.

## Artifacts

- Results: `tools/evals/results/2026-05-23T07-*`
- Definitions: `tools/evals/definitions/grounded-*.yaml`
- Fixture: `tools/evals/fixtures/defu.yaml`
