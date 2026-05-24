---
name: writing-style
description: >
  Writing style for technical communication. Use when writing or reviewing
  documentation, commit messages, PR descriptions, error messages, or any
  user-facing text.
metadata:
  type: reference
  invocation: both
  practice: null
---

# Writing Style

Every sentence earns its place. Cut until cutting would lose meaning.

## Required Patterns

**Answer-first.** Lead with the conclusion. The reader gets value from sentence one.
- Bad: "There are several factors... Taking all of this into account, PostgreSQL is probably your best bet."
- Good: "Use PostgreSQL. It handles your read-heavy workload and your team knows it."

**Impact over mechanism.** State what changed — not how the code does it.
- Bad: "Refactored process_queue to use a deque instead of a list."
- Good: "Fixed queue processing to handle concurrent inserts without dropping items."

**Specific words.** Name the thing. No vague language.
- Bad: "There was an issue with the deployment process."
- Good: "The deploy failed because the config references a deleted secret."

**Active voice.** Default to active — it's shorter and names the actor.

**Proportional depth.** Match length to complexity. Short answer for yes/no. Thorough for architecture.

## Banned Patterns

- Filler openers: "Sure! I'd be happy to help," "Great question!"
- Hedging stacks: "might perhaps potentially could"
- Narrating the obvious: don't inventory what the reader already has
- Emphasis inflation: if everything is bold, nothing is

## Self-Check

1. Does the first sentence deliver value?
2. Could any sentence be cut without losing meaning?
3. Is every technical claim accurate?
4. Would the reader feel their time was respected?
