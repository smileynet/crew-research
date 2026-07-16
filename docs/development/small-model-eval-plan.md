# Small Model Eval Comparison Plan

## Objective

Validate that GLM-5.2 (flat-rate via Z.AI Coding Plan) is competitive with leading external small/fast models on typical small_model workloads. If GLM-5.2 matches or beats the paid alternatives, we use it for everything and avoid per-token costs entirely.

## Key Question

"Does my flat-rate GLM-5.2 match or beat paid small-model alternatives on the tasks that matter?"

## Models Under Test

| Model | Provider | Adapter | Why included |
|-------|----------|---------|-------------|
| GLM-5.2 | Z.AI (Coding Plan) | crush | Flat-rate candidate — free at margin on Max plan |
| Claude 4.5 Haiku | Anthropic | kiro-cli | Premium external baseline — established quality |
| GPT-4.1-nano | OpenAI | codex | Cheapest external competitor ($0.10/1M input) |
| Gemini 3.1 Flash-Lite | Google | agy | Fastest external competitor (363 tok/s) |

## Eval Definitions

5 definitions testing core small_model workloads:

| Definition | Tasks | What it measures |
|-----------|-------|------------------|
| `small-model-commit-message` | 3 | Generate conventional commits from diffs |
| `small-model-code-summary` | 3 | One-sentence code summarization |
| `small-model-instruction-following` | 4 | Format compliance, constraint adherence |
| `small-model-code-edit` | 3 | Surgical code transforms |
| `small-model-tool-calling` | 3 | Tool selection and parameter inference |

Total: 16 tasks × 3 trials × 4 models = **192 individual runs**

## How to Run

```bash
# GLM-5.2 (Z.AI Coding Plan — flat rate)
for def in small-model-commit-message small-model-code-summary small-model-instruction-following small-model-code-edit small-model-tool-calling; do
  mise run eval:one -- --adapter crush --model zai/glm-5.2 --definition $def
done

# Claude 4.5 Haiku
for def in small-model-commit-message small-model-code-summary small-model-instruction-following small-model-code-edit small-model-tool-calling; do
  mise run eval:one -- --adapter kiro-cli --model claude-haiku-4-5-20250414 --definition $def
done

# GPT-4.1-nano
for def in small-model-commit-message small-model-code-summary small-model-instruction-following small-model-code-edit small-model-tool-calling; do
  mise run eval:one -- --adapter codex --model gpt-4.1-nano --definition $def
done

# Gemini 3.1 Flash-Lite
for def in small-model-commit-message small-model-code-summary small-model-instruction-following small-model-code-edit small-model-tool-calling; do
  mise run eval:one -- --adapter agy --model gemini-3.1-flash-lite --definition $def
done
```

## Scoring Dimensions

Each model gets scored on:

1. **Quality** — Average score across all tasks (1-5 scale, threshold 3.5)
2. **Consistency** — Variance across trials (lower is better)
3. **Format compliance** — % of responses with zero surrounding text
4. **Value** — GLM-5.2 is effectively free; externals must justify their per-token cost with measurably better quality

## Expected Outcome

The eval should answer:
- Is GLM-5.2 (Opus-class, flat-rate) overkill but good enough for small tasks?
- Does GPT-4.1-nano's speed advantage translate to better format compliance?
- Does Haiku's established quality justify paying $1.00/1M input when GLM-5.2 is free?
- Is Flash-Lite's 363 tok/s speed useful when GLM-5.2 quality is higher?

## Decision Criteria

**If GLM-5.2 scores ≥4.0 average** — use it for everything, no separate small model needed.

**If GLM-5.2 scores 3.5–4.0** — still use it (free beats marginally better paid), but note quality gaps.

**If GLM-5.2 scores <3.5 on any category** — investigate whether that category justifies routing to an external model.

Secondary: if an external model scores ≥4.5 on instruction-following while GLM-5.2 is <3.5, that's a signal the quota burn of a separate model might be worth it for tool-calling/agent tasks.

## Notes

- GLM-5.2 is "Opus-class" per Z.AI's positioning — it should dominate on quality. The real question is whether it follows small-model constraints (conciseness, format compliance) as well as models trained for that role.
- On Max plan, GLM-5.2 burns 3x quota during peak, 1x off-peak (1x promo through Sept 2026). Budget ceiling is ~530 prompts/5h at peak if all GLM-5.2.
- The eval uses text-based tool selection (not native function calling) to normalize across providers.
- Timeout: 45-60s per task.
