---
title: "E15: Cross-Skill Link Activation Results"
date: 2026-05-27
status: complete
skills: []
---

# E15: Cross-Skill Link Activation Results

## Summary

**Cross-skill linking does NOT reliably trigger progressive loading in kiro-cli.** No treatment achieved the >60% activation threshold. The mechanism is not viable as an activation improvement strategy.

## Method

- Host skill: script-authoring (100% in E7, 60-80% in isolated workspace)
- Target skill: ai-generation-hygiene (20% in E7, 0% baseline here)
- 5 tasks that activate script-authoring but not ai-generation-hygiene
- 4 conditions tested

## Results

| Condition | Host Activation | Target Activation | Delta vs Baseline |
|-----------|:-:|:-:|:-:|
| Baseline (no cross-link) | 3/5 (60%) | 0/5 (0%) | — |
| Treatment A (markdown link) | 4/5 (80%) | 1/5 (20%) | +20% |
| Treatment B (inline mention) | 4/5 (80%) | 1/5 (20%) | +20% |
| Treatment C (companion file) | 4/5 (80%) | 0/5 (0%) | +0% |

## Analysis

### Finding 1: Cross-skill links do not trigger progressive loading

A markdown link like `[hygiene rules](../ai-generation-hygiene/SKILL.md)` in the host skill does NOT cause kiro-cli to load the target skill. The 1/5 activation in treatments A and B is within noise — it's the same rate ai-generation-hygiene achieves on its own (20% in E7) when the task happens to contain the word "generate."

### Finding 2: Companion files are not read during task execution

Treatment C placed the full target skill content as a companion file within the host skill's directory. It was never loaded (0% activation). This means kiro-cli does NOT follow relative links from a loaded skill to companion files during a single-turn task.

**Caveat**: This may differ for multi-turn conversations where the agent has more opportunity to explore. Our test uses `--no-interactive` single-turn invocations.

### Finding 3: The host skill's activation improved across all treatments

Host activation went from 60% (baseline) to 80% (all treatments). Adding ANY content to the skill (even just 3 lines) may have improved its description matching slightly, or this is noise from the small sample size.

### Finding 4: Link vs mention makes no difference

Treatment A (markdown link) and Treatment B (plain text mention) produced identical results. The mechanism doesn't matter — kiro-cli doesn't distinguish between linked and unlinked text within a skill.

## Conclusion

**Cross-skill linking is NOT a viable activation strategy for kiro-cli.** The tool does not follow markdown links between skills or to companion files during single-turn task execution.

## Implications for E16

Since linking doesn't work, the options for fixing failing skills are:
1. **Description rewriting** — add more trigger words to the description
2. **Eager loading** — move to steering (always-on)
3. **Accept the limitation** — these skills work when forced/loaded, just don't auto-activate

E16 should test options 1 and 2.

## Additional Finding: Treatment D (Strong Directive)

Added a 4th treatment with explicit imperative: "After writing the script, read [references/code-hygiene.md](references/code-hygiene.md) and verify your output does not contain any of the listed anti-patterns. Fix all violations before responding."

Result: host 4/5 (80%), target 0/5 (0%).

**Conversation analysis** revealed:
- The agent DID see the directive (it referenced "code-hygiene" in its reasoning)
- The agent did NOT follow the link to read the companion file
- The agent asked clarifying questions instead of writing code (empty workspace → no code to check)

**Root causes**:
1. kiro-cli does not proactively follow relative file links from loaded skill content
2. The agent only reads companion files when it actively decides it needs more information
3. Our test environment (empty workspace) prevented the agent from reaching the "before delivering" step where the directive would apply

**Caveat**: In a real project with existing code, the agent might reach the delivery step and follow the directive. But this would require multi-turn interaction, not single-turn `--no-interactive` mode.

## Refined Conclusion

Cross-skill linking via markdown links is not viable for **automatic activation** in single-turn non-interactive mode. However, the mechanism may work differently in:
- Multi-turn interactive sessions (agent has more turns to follow links)
- Tasks where the agent actually produces output (reaching the "before delivering" step)
- Scenarios where the agent actively seeks more information

For E16, the practical options remain: **description rewriting** or **eager loading**.

## Data

- `tools/evals/results/e15-baseline-2026-05-27T19-57-43Z/`
- `tools/evals/results/e15-link-2026-05-27T20-00-39Z/`
- `tools/evals/results/e15-mention-2026-05-27T20-03-55Z/`
- `tools/evals/results/e15-companion-2026-05-27T20-06-43Z/`
- `tools/evals/results/e15-directive-2026-05-27T21-36-09Z/`
