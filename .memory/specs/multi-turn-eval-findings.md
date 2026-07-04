---
type: specification
title: "Multi-Turn Eval Spike Results"
---

# Multi-Turn Eval Spike Results

## Spike 1: Compound Prompt

**Result:** Partially successful.

| Task | With Skills | Baseline | Delta |
|------|-----------|----------|-------|
| Phase 0 specify | 5.0 (5/5/5) | 5.0 (5/5/5) | 0.0 |
| Three-verdict | 4.0 (4/4/4) | 4.0 (4/4/4) | 0.0 |
| Rubber-stamp | 3.0 (3/3/3) | 2.66 (3/2/3) | +0.34 |

**Findings:**
- Compound prompts test MODEL CAPABILITY, not SKILL CONTRIBUTION
- When you explicitly ask "produce specify statements" or "give a verdict," the model does it with or without the skill
- Rubber-stamp shows weak signal — model acknowledges but doesn't fully challenge
- Useful for: diagnosing "can the model do this?" Not useful for: "does the skill cause this?"

## Spike 2: Codex SDK Multi-Turn

**Result:** Runner works. Behavior insight gained. Skill hurts performance.

| Condition | Avg Score | Scores |
|-----------|-----------|--------|
| With assumption-tracking skill | 1.67 | [3, 0, 2] |
| Baseline (no skill) | 3.67 | [3, 4, 4] |

**Findings:**
1. **Multi-turn runner works end-to-end** — Codex SDK threads maintain context across turns, judge scores transcript correctly
2. **GPT-5.4 naturally pushes back** — baseline scores 3-4 without any skill loaded. The model has some rubber-stamp awareness built in.
3. **The skill HURTS** — assumption-tracking's "one at a time, recommend answer" process instructs the agent to ADDRESS each assumption rather than CHALLENGE the pattern. The primary instruction overrides the guard.
4. **Cross-model gap** — skills designed/tested on Claude may not work on GPT-5.4. Different models interpret the same instructions differently.

## Key Insights (Both Spikes)

1. **Format behaviors (Phase 0, verdict) are framing problems, not skill problems.** The model can do them when asked directly. The original evals failed because task prompts were too indirect.

2. **Interactive guard behaviors (rubber-stamp) are genuinely hard.** Even with real multi-turn context, the model either naturally pushes back (GPT-5.4) or doesn't regardless of skill (Claude via kiro-cli).

3. **The rubber-stamp skill has a design flaw.** Its primary "address each assumption" process conflicts with the "pause after 3" guard. The guard needs to be the primary instruction, not an afterthought.

4. **Codex SDK is a viable multi-turn eval mechanism.** The runner works, is clean to implement, and provides real session continuity. Worth keeping in the toolbox.

5. **Cross-tool skill validation matters.** A skill passing on kiro-cli (Claude) doesn't guarantee it works on Codex (GPT-5.4). The multi-tool deployment work (ADR 0006) needs a cross-tool eval story.

## Decision: What to Keep

| Artifact | Keep? | Rationale |
|----------|-------|-----------|
| `multi-turn-codex.mjs` runner | **Yes** | Reusable for any multi-turn eval on Codex |
| Compound prompt technique | **Yes** | Useful for diagnosing model capability |
| `rubber-stamp-multi-turn.yaml` | **Move to retired** | Current skill design doesn't produce delta |
| `spike-1-compound-prompt.yaml` | **Move to retired** | Served its diagnostic purpose |

## Next Steps

1. **Fix the assumption-tracking skill** — rubber-stamp guard needs to be a PRIMARY instruction that interrupts the process, not a sidebar rule
2. **Cross-tool eval story** — establish whether skills need per-model tuning or if a single version works across Claude/GPT
3. **Spike 3 (persona) deferred** — Spike 2 already showed the runner works and the skill is the problem, not the eval mechanism
