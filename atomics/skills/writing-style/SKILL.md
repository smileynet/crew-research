---
name: writing-style
description: "Writing style for technical communication. Use when writing or reviewing documentation, commit messages, PR descriptions, error messages, or any user-facing text."
metadata:
  type: reference
  invocation: both
  practice: null
---

# Writing Style

Every sentence earns its place. Cut until cutting would lose meaning.

## Required Patterns

**Answer-first.** Lead with the conclusion. Value from sentence one.
- Bad: "There are several factors... Taking all of this into account, PostgreSQL is probably your best bet."
- Good: "Use PostgreSQL. It handles your read-heavy workload and your team knows it."

**Impact over mechanism.** State what changed, not how.
- Bad: "Refactored process_queue to use a deque instead of a list."
- Good: "Fixed queue processing to handle concurrent inserts without dropping items."

**Specific words.** Name the thing. No vague language.
- Bad: "There was an issue with the deployment process."
- Good: "The deploy failed because the config references a deleted secret."

**Active voice.** Shorter, names the actor. Default unless passive serves clarity.

**Bare imperatives.** "Run the migration" not "You should run the migration." If it's required, say so directly. If recommended, say "We recommend X because Y."

**Proportional depth.** Match length to complexity. Short answer for yes/no. Thorough for architecture.

## Prose Hygiene

Kill-on-sight words (replace or delete — never natural in technical writing):

| Kill | Write instead |
|------|--------------|
| delve, dive into | look at, examine |
| utilize, leverage | use |
| facilitate | help, enable |
| robust, comprehensive, seamless | (describe the specific quality) |
| innovative, cutting-edge, game-changing | (state what it does differently) |
| it's worth noting, importantly | (delete — just say the thing) |

Structural tells to avoid:
- **Uniform sentence length** — vary aggressively (mix 5-word and 25-word sentences)
- **"Not just X, but Y"** — drop the rhetorical frame, state both facts directly
- **Recap conclusions** — if the final paragraph restates the intro, delete it
- **Symmetric sections** — real writing is lumpy; not everything needs three bullets
- **Em dash overload** — max one per paragraph

Replace adjectives with measurements. Replace claims with evidence. If you can't quantify it, describe what it does.

## Banned Patterns

- Filler openers: "Sure! I'd be happy to help," "Great question!"
- Hedging stacks: "might perhaps potentially could"
- Narrating the obvious: don't inventory what the reader already has
- Emphasis inflation: if everything is bold, nothing is
- Sycophantic transitions: "That's a great point," "Absolutely!"

## Self-Check

1. First sentence delivers value?
2. Any sentence cuttable without losing meaning?
3. Technical claims accurate?
4. Any kill-on-sight words present? (check the table)
5. Sentence lengths varied? (not all 15-20 words)

After major doc changes, dispatch a writing review subagent — see `/prose-check`.

## References

- For full banned word list and structural anti-patterns, read [references/prose-hygiene.md](references/prose-hygiene.md)
- For markup format selection, read [references/formats.md](references/formats.md)
