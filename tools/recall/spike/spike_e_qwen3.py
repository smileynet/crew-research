"""Spike Model E: qwen3-embedding:0.6b (639MB, 1024d MRL, 32K token context)

NOTE: This model may not have an ONNX export. If not available, we test via
Ollama's /api/embed endpoint (requires `ollama pull qwen3-embedding:0.6b`).
Falls back gracefully and documents the dependency.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def _try_onnx():
    """Attempt ONNX-based loading."""
    from huggingface_hub import hf_hub_download
    from onnxruntime import InferenceSession
    from tokenizers import Tokenizer
    import numpy as np

    # Try known ONNX export locations
    candidates = [
        ("Qwen/Qwen3-Embedding-0.6B", "onnx/model.onnx"),
        ("Xenova/qwen3-embedding-0.6b", "onnx/model_quantized.onnx"),
    ]

    for model_id, filename in candidates:
        try:
            model_path = hf_hub_download(model_id, filename)
            tokenizer_path = hf_hub_download(model_id, "tokenizer.json")
            return model_path, tokenizer_path
        except Exception:
            continue
    return None, None


def _try_ollama():
    """Use Ollama's /api/embed endpoint."""
    import urllib.request
    import json

    def embed(text: str) -> list[float]:
        payload = json.dumps({"model": "qwen3-embedding:0.6b", "input": text}).encode()
        req = urllib.request.Request(
            "http://localhost:11434/api/embed",
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=30) as resp:
            result = json.loads(resp.read())
        return result["embeddings"][0]

    def embed_batch(texts: list[str]) -> list[list[float]]:
        payload = json.dumps({"model": "qwen3-embedding:0.6b", "input": texts}).encode()
        req = urllib.request.Request(
            "http://localhost:11434/api/embed",
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read())
        return result["embeddings"]

    return embed, embed_batch


def main():
    import numpy as np

    DIMENSION = 1024

    # Try ONNX first
    model_path, tokenizer_path = _try_onnx()

    if model_path:
        print("Using ONNX export")
        from onnxruntime import InferenceSession
        from tokenizers import Tokenizer

        session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
        tokenizer = Tokenizer.from_file(tokenizer_path)
        tokenizer.enable_truncation(max_length=8192)

        input_names = [i.name for i in session.get_inputs()]

        def embed(text: str) -> list[float]:
            encoded = tokenizer.encode(text)
            input_ids = np.array([encoded.ids], dtype=np.int64)
            attention_mask = np.array([encoded.attention_mask], dtype=np.int64)
            inputs = {"input_ids": input_ids, "attention_mask": attention_mask}
            if "token_type_ids" in input_names:
                inputs["token_type_ids"] = np.zeros_like(input_ids)
            outputs = session.run(None, inputs)
            if outputs[0].ndim == 2:
                pooled = outputs[0][0]
            else:
                token_embeddings = outputs[0]
                mask = attention_mask[0]
                masked = token_embeddings[0] * mask[:, None]
                pooled = masked.sum(axis=0) / mask.sum()
            pooled = pooled[:DIMENSION]
            norm = np.linalg.norm(pooled)
            return (pooled / norm).tolist()

        def embed_batch(texts: list[str]) -> list[list[float]]:
            return [embed(t) for t in texts]
    else:
        # Fall back to Ollama
        print("No ONNX export found. Attempting Ollama (requires: ollama pull qwen3-embedding:0.6b)")
        try:
            embed, embed_batch = _try_ollama()
            # Verify it works
            test = embed("test")
            DIMENSION = len(test)
            print(f"  Ollama working, dimension={DIMENSION}")
        except Exception as e:
            print(f"  ERROR: Ollama not available: {e}")
            print("  SKIP: Model E requires Ollama. Install with: ollama pull qwen3-embedding:0.6b")
            return

    run_spike(
        model_name="qwen3-embedding-0.6b",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=639,
    )


if __name__ == "__main__":
    main()
