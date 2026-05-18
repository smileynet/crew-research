---
name: research-prior-art
description: "Research best practices, anti-patterns, and prior art from reference repos to inform a design decision. Use during grill-with-docs sessions when a question needs evidence before recommending."
---

Research the following design question against our reference repos and external prior art, then update the recommendation based on findings.

## Question to Research

{question}

## Research Process

1. **Check best_practices/docs/practices/** — look for a practice doc that directly addresses this concern
2. **Check agent-crews/docs/adr/** — look for architectural decisions that resolved similar questions
3. **Check ai-references/** — look for how matt-skills, indydevdan, and nicobailon handled this
4. **Check agent-crews/shared/skills/** — look for skill design patterns relevant to the question
5. **Synthesize** — identify the cross-tool consensus, meaningful differences, and anti-patterns

## Output Format

### Findings
- What the authoritative practice docs say
- What the ADRs decided and why
- How different tools/authors handled it
- Anti-patterns identified

### Cross-Tool Consensus
What all sources agree on (the safe common ground).

### Meaningful Differences
Where sources disagree and why (situational alternatives worth preserving).

### Updated Recommendation
The original recommendation, confirmed or revised, with evidence citations.
