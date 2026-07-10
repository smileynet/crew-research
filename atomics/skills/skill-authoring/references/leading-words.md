# Leading Words

A leading word is a compact concept from the model's pretraining that anchors agent behavior in few tokens. It recruits priors the model already holds — giving you behavioral precision without verbose instruction.

## In the skill body

A leading word repeated throughout the text accumulates a distributed definition. The agent reaches for the same behavior every time it encounters the word.

| Verbose instruction | Leading word | Why it works |
|---|---|---|
| "fast, deterministic, low-overhead, clear signal" | **tight** | Pretrained: "tight loop" = optimized, minimal, fast |
| "a loop that detects exactly this bug" | **red** | Pretrained: "goes red" = binary fail state (CI, tests) |
| "large behavior behind small interface" | **deep** | Pretrained: Ousterhout's deep-module concept |
| "unknown scope discovered progressively" | **fog** | Pretrained: fog-of-war = revealed by exploration |
| "smallest end-to-end path through all layers" | **tracer** | Pretrained: tracer bullet = thin but complete |

## In the description

The same word in your description anchors invocation: when the user's prompt contains the leading word, semantic matching fires more reliably. "Tight feedback loop" in both the description and common user prompts creates a strong activation bridge.

## Finding leading words

Look for these patterns in skill text:

1. **Three-word phrases restated multiple times** → collapse to one pretrained word
2. **Sentences that gesture at a concept without naming it** → name it
3. **Behavioral instructions that could be a single metaphor** → use the metaphor

## Refactoring to leading words

Before:
> "The feedback loop should produce a clear pass/fail binary signal with minimal setup time and no external dependencies that could introduce non-determinism."

After:
> "Make the loop **tight** — fast, deterministic, binary."

Same meaning. 5 tokens instead of 30. Stronger behavioral anchoring.

## Anti-pattern: invented jargon

Leading words MUST exist in pretraining. Invented terms (neologisms) don't recruit priors — they're just labels the agent has to learn from your text alone.

- ✅ "tight" (millions of training examples)
- ✅ "red/green" (CI, TDD, traffic lights)
- ❌ "crunchify" (invented, no priors)
- ❌ "hyper-optimize-loop" (compound, no single concept)

Use existing concepts. Don't invent.
