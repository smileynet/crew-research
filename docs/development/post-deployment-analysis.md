# Post-Deployment Analysis — Follow-Up Items

After sustained use on real projects, evaluate these decisions:

## Steering Placement Questions

| Item | Current | Question | Signal to move |
|------|---------|----------|---------------|
| research-dispatch | Steering (always-on) | Does the agent follow this pattern without being told? Is it too prescriptive for simple lookups? | Agent dispatches subagents for single-question research (overkill) |
| project-conventions | Steering | Is "update CONTEXT.md immediately" actually followed? Does it cause noise? | Agent updates CONTEXT.md with trivial terms, or never updates it |
| ai-generation-hygiene | Steering | Does the baseline model already produce clean code without this? | No measurable quality difference with/without |
| verification-protocol | Steering | Does the agent verify without this steering? | Agent already verifies via built-in behavior |

**Action**: After 2-4 weeks of real use, run @project-audit and check whether steering rules are being followed. If a rule is always followed without steering (model default), remove it. If a rule causes unwanted behavior, move to on-demand skill.

## Skill Effectiveness Questions

| Question | How to test |
|----------|-------------|
| Do users actually invoke @plan-prereqs, or do they just ask naturally? | Check session transcripts for prompt invocations vs natural language |
| Is @adopt-project useful, or do users just run init directly? | Track whether brownfield projects lose customizations |
| Does the spike/tracer/prototype framework in planning-cycles get used? | Check if agents reference the decision heuristic |
| Are there skills that never activate in real work? | Run E7-style activation analysis on real session data |

## Architecture Questions

| Question | How to evaluate |
|----------|----------------|
| Is 4 steering files too much context cost? | Measure token usage with/without steering on real tasks |
| Should research-dispatch be a skill that activates on "research X" instead? | Check if it fires inappropriately on simple questions |
| Is the idempotent init pattern working? | Track whether re-runs cause issues or confusion |
| Do users customize .crew-config.yaml, or ignore it? | Check deployed projects after 1 month |

## When to Evaluate

- **2 weeks**: First check — are steering rules being followed? Any obvious misfires?
- **1 month**: Full audit — which skills activate? Which prompts get used? Any gaps?
- **3 months**: Architecture review — is the tier split right? Should anything move between tiers?
