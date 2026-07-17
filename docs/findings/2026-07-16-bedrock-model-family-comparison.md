# Bedrock Model Family Comparison — Eval Results

**Date:** July 15–16, 2026
**Author:** sabiggin
**Harness:** `tools/evals/harness/run-model-comparison.sh`
**Results:** `tools/evals/results/model-comparison-2026-07-15T21-01-41Z/` (main), `model-comparison-2026-07-16T02-48-35Z/` (GPT supplement)

## Summary

Evaluated 8 model families available on Amazon Bedrock via CloseCode (Bedrock-only OpenCode fork) across 7 agentic coding tasks, 3 trials each. Judge: Claude Opus 4.8, temperature=0.

**Top finding:** Only frontier models (Claude Sonnet 5, GPT-5.4) reliably produce working code. Open-weight models excel at comprehension and reasoning but fail on code generation tasks requiring multi-feature implementation.

## Setup

### Tools
- **CloseCode** v1.17.18-amzn.1.36 — Bedrock-only fork of OpenCode (personal project by aayusoni@, not ASR-approved)
- **Kiro CLI** — for Claude Sonnet 5 invocation and judging
- **Codex** v0.144.4.268 — tested but GPT-5.5 requires codex-specific credentials

### Models Tested

| Key | Model ID | Family | Params | Notes |
|-----|----------|--------|--------|-------|
| claude | `anthropic.claude-sonnet-5` | Anthropic | Unknown (closed) | Latest Sonnet, Jun 30 2026 |
| gpt | `openai.gpt-5.4` | OpenAI | Unknown (closed) | GPT-5.5 inaccessible via personal ADA; 5.6 in limited preview |
| glm | `zai.glm-5` | Z.ai (Zhipu) | 744B MoE / 40B active | Latest on Bedrock; GLM-5.2 (Jun 2026) not yet available |
| kimi | `moonshot.kimi-k2-thinking` | Moonshot AI | 1T MoE / 32B active | K2.7 Code (Jun 2026) not yet available |
| qwen | `qwen.qwen3-coder-480b-a35b-v1:0` | Alibaba | 480B MoE / 35B active | Qwen3.7-Max not on Bedrock |
| mistral | `mistral.devstral-2-123b` | Mistral AI | 123B dense | Medium 3.5 (128B) not on Bedrock yet |
| grok | `xai.grok-4.3` | xAI | Unknown (closed) | Current on Bedrock |
| minimax | `minimax.minimax-m2.5` | MiniMax | 230B MoE / 10B active | Current on Bedrock |

### Models Excluded

| Model | Reason |
|-------|--------|
| DeepSeek V3.2 / R1 | "Invalid model identifier" — account access not provisioned |
| Meta Llama 4 Maverick | Requires inference profile prefix + max_tokens < 8192 |
| GPT-5.5 | Only accessible via codex wrapper credentials, not personal ADA |

### Tasks (7)

| # | Task | Category | What It Tests |
|---|------|----------|---------------|
| T1 | Code Comprehension | understanding | Read code, explain, find bugs (merge_intervals mutation bug) |
| T2 | Bug Diagnosis | debugging | Given TypeError + code, locate root cause (API error shape) |
| T3 | Code Generation | implementation | Implement debounce with leading/maxWait/cancel from spec |
| T4 | Refactoring | transformation | Flatten nested conditionals into data-driven approach |
| T5 | Planning Before Acting | agentic | Rate limiter design for distributed system (plan first) |
| T6 | Instruction Following | compliance | Implement function following 6 explicit constraints |
| T7 | Tool-Use Reasoning | agentic | Production debugging investigation plan with prioritization |

## Results

### Leaderboard

| Rank | Model | Family | Overall | Avg Latency |
|:----:|-------|--------|:-------:|:-----------:|
| 1 | Claude Sonnet 5 | Anthropic | **4.48/5** | 29.6s |
| 2 | GPT-5.4 | OpenAI | **4.29/5** | 32.2s |
| 3 | MiniMax M2.5 | MiniMax | **3.19/5** | 15.9s |
| 4 | GLM-5 | Z.ai | **3.14/5** | 16.5s |
| 5 | Qwen3 Coder 480B | Alibaba | **2.86/5** | 22.9s |
| 6 | Grok 4.3 | xAI | **2.76/5** | 9.9s |
| 7 | Kimi K2 Thinking | Moonshot | **2.38/5** | 19.7s |
| 8 | Devstral 2 123B | Mistral | **2.33/5** | 38.2s |

### Per-Task Scores (avg of 3 trials)

| Task | Claude | GPT | MiniMax | GLM | Qwen | Grok | Kimi | Mistral |
|------|:------:|:---:|:-------:|:---:|:----:|:----:|:----:|:-------:|
| Code Comprehension | **5.0** | 4.3 | 4.3 | 3.7 | 4.0 | 4.3 | 3.3 | 4.0 |
| Bug Diagnosis | **4.0** | **4.0** | **4.0** | 3.0 | 3.3 | 3.0 | 2.7 | 2.3 |
| Code Generation | **4.0** | **4.0** | 1.0 | 1.0 | 0.7 | 1.0 | 1.0 | 0.7 |
| Refactoring | **4.7** | 3.7 | 3.0 | 3.0 | **4.0** | 3.3 | 2.3 | 2.7 |
| Planning | **5.0** | **5.0** | 3.7 | 4.0 | 2.0 | 1.7 | 2.0 | 2.0 |
| Instruction Following | 3.7 | **5.0** | 2.3 | 3.3 | 3.0 | 3.3 | 2.0 | 1.0 |
| Tool-Use Reasoning | **5.0** | 4.0 | **4.0** | **4.0** | 3.0 | 2.7 | 3.3 | 3.7 |

### Consistency (Stddev Analysis)

| Model | Typical Stddev | Assessment |
|-------|:--------------:|------------|
| Claude Sonnet 5 | 0.0–0.47 | Very consistent — same score across trials |
| GPT-5.4 | 0.0–0.47 | Very consistent |
| MiniMax M2.5 | 0.0–1.25 | Moderate — occasional outlier trial |
| GLM-5 | 0.0–1.25 | Moderate — code comprehension varies (2,5,4) |
| Qwen3 Coder | 0.0–1.63 | Variable — planning swings wildly (0,4,2) |
| Grok 4.3 | 0.0–0.47 | Consistent — but consistently mediocre |
| Kimi K2 Thinking | 0.0–1.89 | **Highly inconsistent** — scores range 1–5 on same task |
| Devstral 2 123B | 0.0–1.25 | Inconsistent with frequent timeouts/errors |

## Analysis

### Tier Classification

**Tier 1 — Production-ready for agentic coding (>4.0 overall):**
- Claude Sonnet 5, GPT-5.4
- Both handle all task types reliably with low variance

**Tier 2 — Useful for specific tasks (3.0–3.5 overall):**
- MiniMax M2.5: Strong on comprehension, diagnosis, reasoning. Cheap.
- GLM-5: Good at planning and tool-use reasoning. Consistent.
- Qwen3 Coder: Best non-frontier refactoring. Inconsistent elsewhere.

**Tier 3 — Limited utility in current Bedrock versions (<3.0 overall):**
- Grok 4.3: Fastest model (9.9s). Only useful for quick reads.
- Kimi K2 Thinking: Brilliant sometimes, fails others. Unreliable.
- Devstral 2 123B: Slowest AND lowest quality. Surprising given its open-source claims.

### Critical Pattern: Code Generation Gap

The debounce implementation task (T3) was the sharpest discriminator:

| Score | Models | Behavior |
|-------|--------|----------|
| 4.0 | Claude, GPT | Complete implementation with leading + maxWait + cancel |
| 1.0 | GLM, Grok, Kimi, MiniMax | Partial implementation, missing maxWait or broken logic |
| 0.7 | Qwen, Mistral | Incomplete output or timeout before finishing |

**Hypothesis:** The `closecode run` non-interactive mode may truncate long outputs for some models, causing code generation to appear worse than in interactive TUI mode. This needs further investigation.

### Latency vs Quality Tradeoff

```
Quality ▲
5.0 │         ● Claude     ● GPT
    │
4.0 │
    │
3.0 │    ● MiniMax  ● GLM
    │                         ● Qwen
    │  ● Grok
2.0 │                 ● Kimi
    │                                  ● Mistral
1.0 │
    └──────────────────────────────────────────► Latency
        10s      20s      30s      40s
```

Grok is the clear speed winner. For quality, Claude and GPT justify their latency. MiniMax and GLM offer the best middle ground (good quality, half the latency of frontier).

### Version Gap Impact

| Model on Bedrock | Latest Available | Estimated Score Gap |
|------------------|-----------------|:-------------------:|
| GLM-5 → GLM-5.2 | +1M context, better coding | Likely +0.5–1.0 |
| Kimi K2 → K2.7 Code | Purpose-built for MCP coding | Likely +1.0–1.5 |
| DeepSeek V3.2 → V4-Pro | 80.6% SWE-bench | Likely +1.5–2.0 |
| GPT-5.4 → GPT-5.6 Sol | "Best coding model yet" | Likely +0.3–0.5 |

The biggest potential movers are DeepSeek V4 and Kimi K2.7 — neither available on Bedrock today.

## Recommendations

### For Daily Coding Work
1. **Claude Sonnet 5** as default — best overall, worth the 30s latency
2. **GPT-5.4** for instruction-heavy tasks (perfect 5.0) and planning
3. **Grok 4.3** for quick code reading / triage (3x faster)

### For Budget-Conscious Workloads
- **MiniMax M2.5** or **GLM-5** for reasoning/planning tasks at ~1/6 the cost of frontier
- Avoid them for code generation — delegate that to Claude/GPT

### For Model Selection in CloseCode
```bash
# Default (best quality)
closecode run --model amazon-bedrock/anthropic.claude-sonnet-5 "task"

# Fast triage
closecode run --model amazon-bedrock/xai.grok-4.3 "explain this code"

# Budget reasoning
closecode run --model amazon-bedrock/zai.glm-5 "plan the architecture for..."
```

### Models to Watch (re-eval when available on Bedrock)
1. **DeepSeek V4-Pro** — would likely be Tier 1 at open-weight pricing
2. **Kimi K2.7 Code** — purpose-built for MCP tool use, may outperform on agentic tasks
3. **GLM-5.2** — 1M context + improved coding, MIT license
4. **GPT-5.6 Sol** — limited preview on Bedrock, likely to become default

## Limitations

1. **Judge bias:** Claude Opus 4.8 as sole judge may favor Claude-family outputs. Multi-model consensus judging was not used due to codex/crush adapter issues.
2. **Output truncation:** CloseCode `run` mode may truncate long responses. Interactive TUI mode might produce better results for verbose models (Kimi, Mistral).
3. **Single-turn only:** These evals test single-turn generation. Multi-turn agentic performance (tool loops, iterative debugging) was not measured.
4. **No cost data:** Token counts were not captured per-model. Cost-per-task comparison is estimated from latency only.
5. **Account access gaps:** DeepSeek, Llama 4, and GPT-5.5 were untestable due to credential/access issues.

## Reproduction

```bash
# Full run (8 models, 7 tasks, 3 trials)
cd ~/code/crew-research
tools/evals/harness/run-model-comparison.sh --trials 3

# Single model
tools/evals/harness/run-model-comparison.sh --models "glm" --trials 3

# Dry-run
tools/evals/harness/run-model-comparison.sh --dry-run
```

## Related Files

- Experiment definition: `tools/evals/experiments/bedrock-model-family-comparison.yaml`
- Runner script: `tools/evals/harness/run-model-comparison.sh`
- CloseCode adapter: `tools/proofs/adapters/closecode.yaml`
- Raw results: `tools/evals/results/model-comparison-2026-07-15T21-01-41Z/`
- GPT supplement: `tools/evals/results/model-comparison-2026-07-16T02-48-35Z/`
