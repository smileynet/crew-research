# Subagent Research Dispatch

When a design question has 3+ viable options AND the user explicitly requests deeper research (e.g., "research this", "investigate options", "find prior art"):

## When to dispatch

- Architectural questions with competing patterns (each needs its own research track)
- Questions where internal prior art would be decisive
- Questions where documented behavior vs actual behavior diverges

## When NOT to dispatch

- Simple preference questions (just ask the user)
- Questions answerable from already-fetched documentation
- Questions where the codebase already answers (read it directly)

## Dispatch pattern

3-4 parallel subagent stages (blocking):

| Stage | Focus | Search strategy |
|-------|-------|----------------|
| 1 | Official docs deep-dive | AWS/library documentation for THIS specific pattern |
| 2 | Prior art | Internal systems, open-source examples |
| 3 | Anti-patterns + failure modes | Warnings, migrations away from, post-mortems |
| 4 (optional) | Alternative approaches | What other tools/patterns solve this differently |

## Prompt template for research subagents

Each stage prompt MUST include:
1. The specific question being researched
2. The architectural context (what system this is for)
3. Specific search queries to execute
4. Expected output format (structured markdown with sources)
5. Instruction to cite every claim with URL

## After results return

1. Synthesize findings across all stages
2. Update the recommendation based on evidence (don't lock in before research)
3. Present consolidated options table with sources from all stages
4. Note where stages disagreed (conflicting evidence = important signal)

## Failure handling

Per subagent-reliability steering:
- If any stage returns empty, report it and state what coverage was lost
- If 2+ stages fail, fall back to sequential research in main context
- Never silently absorb partial research — declare coverage gaps
