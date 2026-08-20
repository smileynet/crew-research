# Prose Hygiene — Full Reference

Loaded on demand when writing-style activates and prose needs detailed checking.

## Kill-On-Sight Words

Never use in technical writing. Always a better alternative:

| Category | Kill | Write instead |
|----------|------|--------------|
| Verbs | delve, utilize, leverage, facilitate, elucidate, embark, endeavor, encompass | dig into, use, help, explain, start, try, include |
| Adjectives | robust, comprehensive, seamless, cutting-edge, innovative, groundbreaking, transformative | (describe the specific quality or measurement) |
| Nouns | tapestry, realm, landscape (metaphorical), paradigm, synergy, myriad, plethora | area, field, space, model, many |
| Phrases | multifaceted, holistic, pivotal, profound, nuanced (as filler) | complex, whole, important, (show the nuance instead) |

## Filler Phrases (Delete Entirely)

These add zero information. The sentence is better without them:

- "It's worth noting that..." / "It's important to note that..."
- "Importantly, ..." / "Notably, ..." / "Interestingly, ..."
- "Let's dive into..." / "Let's explore..."
- "In this section, we will..."
- "As we can see..." / "As mentioned earlier..."
- "Furthermore, ..." / "Moreover, ..." / "Additionally, ..."
- "In today's [fast-paced/digital/modern] world..."
- "Without further ado..."
- "When it comes to..." / "In the realm of..."
- "A [comprehensive/holistic/nuanced] approach to..."

## Structural Anti-Patterns

| Pattern | What it looks like | Fix |
|---------|-------------------|-----|
| Topic sentence machine | Every paragraph: topic → elaboration → example → wrap | Vary structure; sometimes the point comes last |
| Symmetry addiction | Three pros, three cons, five steps, equal sections | Let sections be unequal; real content is lumpy |
| "Not just X, but Y" | "This isn't just a tool — it's a paradigm shift" | State both facts directly without the rhetorical frame |
| List abuse | Bullet lists where prose would be clearer; always 3 or 5 items | Use prose when items are connected; vary list length |
| Recap conclusion | Final paragraph restates the introduction | Delete it. The reader already read the intro. |
| Uniform rhythm | Every sentence 15-20 words, same cadence | Mix: one 5-word sentence, then a 30-word compound |
| Em dash overload | Three em dashes in one paragraph | Max one per paragraph; use commas or periods instead |
| Hedge parade | "Perhaps it might be worth considering that..." | Commit to the statement or cut it |
| Sycophantic opening | "Great question!" / "That's a fantastic point!" | Start with the answer |
| Staccato clusters | Five short declarative sentences in a row | Combine some; vary rhythm |

## Positive Voice Rules

What TO do (not just what to avoid):

- **Vary sentence length aggressively** — at least one under 8 words and one over 20 per paragraph
- **Use contractions** — "it's", "don't", "won't" (signals human writing)
- **Be specific** — names, numbers, file paths instead of abstractions
- **Include friction** — mention tradeoffs, limitations, edge cases (AI defaults to relentless positivity)
- **Use bare imperatives** — "Run the test" not "You should run the test"
- **Let sentences be ugly sometimes** — not every phrase needs to be elegant
- **Use the less obvious word** — "sprawling" beats "large", "brittle" beats "fragile"
- **Measurements over adjectives** — "50ms" beats "fast", "3 lines of code" beats "simple"

## Cluster Detection

A single suspicious word is fine. Three or more in one paragraph signals rewrite needed:
- "robust", "comprehensive", "seamless" in one sentence = rewrite
- "innovative", "cutting-edge", "transformative" in one paragraph = rewrite
- Multiple items from the filler phrases list in one section = rewrite
