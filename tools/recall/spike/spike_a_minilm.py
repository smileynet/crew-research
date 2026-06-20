"""Spike Model A: all-MiniLM-L6-v2 (46MB, 384d, 256 word-piece context)"""

import sys
from pathlib import Path

# Ensure harness is importable
sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def main():
    from tokenizers import Tokenizer
    from onnxruntime import InferenceSession
    from huggingface_hub import hf_hub_download
    import numpy as np

    MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
    DIMENSION = 384

    # Download ONNX model
    print("Downloading model...")
    model_path = hf_hub_download(MODEL_ID, "onnx/model.onnx")
    tokenizer_path = hf_hub_download(MODEL_ID, "tokenizer.json")

    session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    tokenizer = Tokenizer.from_file(tokenizer_path)
    tokenizer.enable_truncation(max_length=256)
    tokenizer.enable_padding(pad_id=0, pad_token="[PAD]", length=256)

    def embed(text: str) -> list[float]:
        encoded = tokenizer.encode(text)
        input_ids = np.array([encoded.ids], dtype=np.int64)
        attention_mask = np.array([encoded.attention_mask], dtype=np.int64)
        token_type_ids = np.zeros_like(input_ids)
        outputs = session.run(None, {
            "input_ids": input_ids,
            "attention_mask": attention_mask,
            "token_type_ids": token_type_ids,
        })
        # Mean pooling over token embeddings
        token_embeddings = outputs[0]  # (1, seq_len, dim)
        mask = attention_mask[0]
        masked = token_embeddings[0] * mask[:, None]
        pooled = masked.sum(axis=0) / mask.sum()
        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_batch(texts: list[str]) -> list[list[float]]:
        return [embed(t) for t in texts]

    run_spike(
        model_name="all-MiniLM-L6-v2",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=46,
    )


if __name__ == "__main__":
    main()
