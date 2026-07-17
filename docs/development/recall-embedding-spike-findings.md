# Embedding Spike Findings

**Date:** 2026-06-20
**Decision:** bge-base-en-v1.5 (int8 ONNX) — 105MB, 768d, MIT license

## Results

| Model | Size | Dim | Recall@3 | Ingest (729 chunks) | Rate | Query p50 |
|-------|------|-----|----------|---------------------|------|-----------|
| all-MiniLM-L6-v2 | 46MB | 384 | 3/5 (60%) | 9.3s | 78/s | 72ms |
| **bge-base-en-v1.5 (int8)** | **105MB** | **768** | **4/5 (80%)** | **51s** | **15/s** | **128ms** |
| bge-large-en-v1.5 (int8) | 321MB | 1024 | 4/5 (80%) | 112s | 7/s | 217ms |
| nomic-embed-text v1.5 | 274MB | 768 | 4/5 (80%) | 296s | 2/s | 217ms |
| mxbai-embed-large-v1 | 670MB | 1024 | 4/5 (80%) | 286s | 3/s | 387ms |
| embeddinggemma-300m | 622MB | 768 | 4/5 (80%) | 1833s | <1/s | 205ms |
| snowflake-arctic-embed-m-v2.0 | 296MB | 768 | 4/5 (80%) | 1788s | <1/s | 1515ms |
| qwen3-embedding:0.6b | 639MB | 1024 | SKIP | — | — | — |

## Key Insight

Int8 quantization is the decisive factor for CPU inference speed. The same model architecture (BGE 109M params) runs 6x faster as int8 than float competitors of similar size. All 768d+ models hit identical 80% recall — the quality ceiling is the test corpus, not the model.

## Why bge-base-en-v1.5 (int8) wins

- **Smallest at 80% recall** — 105MB vs 274MB+ for all alternatives
- **Fastest ingest at 80% recall** — 15 chunks/s vs 2-3/s for nomic/mxbai
- **Fastest queries at 80% recall** — 128ms vs 205-1515ms for alternatives
- **MIT licensed** — no commercial restrictions
- **ONNX ready** — Xenova/bge-base-en-v1.5 on HuggingFace, no conversion needed
- **No task prefixes for documents** — queries need prefix, docs don't (simpler ingest)
- **512 token context** — sufficient for 800-char chunks

## What we eliminated

| Model | Reason |
|-------|--------|
| all-MiniLM-L6-v2 | 60% recall — misses too many queries |
| nomic-embed-text v1.5 | Same recall, 6x slower ingest, 2.6x larger |
| embeddinggemma-300m | Same recall, 36x slower ingest |
| snowflake-arctic-embed-m-v2.0 | Same recall, 12x slower queries (1.5s!) |
| mxbai-embed-large-v1 | Same recall, 6x larger, 3x slower queries |
| bge-large-en-v1.5 (int8) | Same recall, 3x larger/slower than bge-base — no benefit |
| qwen3-embedding:0.6b | Requires Ollama service — violates zero-dependency requirement |
| jina-embeddings-v3 | CC-BY-NC-4.0 license — disqualifying |
| stella_en_1.5B | >1GB — too large |

## The missed query

All models miss query 2: "why did we decide to rebuild from scratch" → expected "ground-up rebuild". This is a chunking/content issue, not an embedding quality issue — the relevant passage exists but doesn't land in the top-3 with any model. Better chunking or larger retrieval window (recall@5) would fix it.

## Implementation spec

```python
# Install
from huggingface_hub import hf_hub_download
model_path = hf_hub_download("Xenova/bge-base-en-v1.5", "onnx/model_quantized.onnx")
tokenizer_path = hf_hub_download("Xenova/bge-base-en-v1.5", "tokenizer.json")

# Load
from onnxruntime import InferenceSession
from tokenizers import Tokenizer
session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
tokenizer = Tokenizer.from_file(tokenizer_path)

# Query embedding (with prefix)
text = "Represent this sentence for searching relevant passages: " + query

# Document embedding (no prefix)
text = document_chunk
```

## Dependencies for recall tool

```
onnxruntime>=1.17.0    # ~12MB wheel
numpy>=1.24.0          # likely already installed
tokenizers>=0.15.0     # ~2.7MB wheel
huggingface_hub>=0.20  # for model download
```

Model downloads on first use: ~105MB (cached in ~/.cache/huggingface/).
