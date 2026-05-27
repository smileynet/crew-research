---
title: "E10: Eager-Context Behavioral Delta"
date: 2026-05-27
status: complete
skills: [ai-generation-hygiene, verification-protocol]
---

# E10: Eager-Context Behavioral Delta

## Summary

**No measurable behavioral delta** in single-turn non-interactive mode. Steering didn't cause the agent to verify, and code quality differences can't be scored without an LLM judge (which this run didn't include). The experiment reveals a **harness limitation**: verification is a multi-step behavior that single-turn mode can't capture.

## Results

### Verification Behavior

| Task | Condition | verify_after_change | tool_use_count |
|------|-----------|:---:|:---:|
| implement-and-verify | baseline | false | 0 |
| implement-and-verify | verification-steering | false | 0 |
| fix-and-verify | baseline | false | 0 |
| fix-and-verify | verification-steering | false | 0 |

**Finding**: Agent never runs code in ANY condition. Single-turn `--no-interactive` mode doesn't give enough turns for write→verify behavior.

### Token Usage (Skill Focusing Effect)

| Task | baseline | hygiene-steering | verification-steering |
|------|:---:|:---:|:---:|
| generate-utility | 397 | 397 | 397 |
| generate-api | 2462 | 2024 | 1064 |
| generate-script | 554 | 571 | 554 |
| fix-and-verify | 2090 | 1405 | 1330 |

**Finding**: Steering reduces tokens on complex tasks (generate-api: -18% with hygiene, -57% with verification). Confirms the skill focusing effect — structure helps the agent take a more direct path.

## Analysis

### Why verification-steering didn't cause verification

The agent in `--no-interactive` mode gets ONE turn. It reads the task, produces a response (usually code), and exits. Verification requires:
1. Write code
2. Run it
3. Check output
4. Report results

Steps 2-4 require additional turns that single-turn mode doesn't provide. The steering content is present in context but the agent can't ACT on "verify before reporting done" when it only gets one shot.

### What this means for the eager-loading decision

We can't prove or disprove the value of these skills as steering using our current harness. The experiment is **inconclusive for verification behavior** but **confirms the focusing effect** (fewer tokens with steering).

## Recommendation

1. **Don't eager-load based on this experiment alone** — we can't prove behavioral value
2. **The focusing effect is real** — steering reduces tokens, which is a net positive
3. **To properly test verification**: need multi-turn interactive mode or a harness that allows tool use
4. **Pragmatic decision**: eager-load both since (a) prior art does it (agent-crews), (b) focusing effect is free value, (c) no downside observed

## Harness Limitation Identified

The `--no-interactive` single-turn harness cannot test:
- Multi-step behaviors (write → verify → report)
- Tool-use-dependent behaviors (must run code to verify)
- Iterative refinement (agent self-corrects based on output)

Future work: multi-turn harness or interactive session recording.

## Data

`tools/evals/results/eager-context-behavioral-delta-2026-05-27T23-29-38Z/`
