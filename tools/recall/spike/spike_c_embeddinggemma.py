"""Spike Model C: embeddinggemma-300m (622MB, 768d MRL, 2K token context)"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def main():
    from tokenizers import Tokenizer
    from onnxruntime import InferenceSession
    from huggingface_hub import hf_hub_download
    import numpy as np

    MODEL_ID = "onnx-community/embeddinggemma-300m-ONNX"
    DIMENSION = 768

    print("Downloading model...")
    from huggingface_hub import snapshot_download

    # embeddinggemma ONNX has external data files - need full directory
    model_dir = snapshot_download(MODEL_ID, allow_patterns=["onnx/*", "tokenizer.json", "tokenizer_config.json"])
    import os
    onnx_dir = os.path.join(model_dir, "onnx")

    # Find the model file
    for candidate in ["model_quantized.onnx", "model_q8.onnx", "model.onnx"]:
        model_path = os.path.join(onnx_dir, candidate)
        if os.path.exists(model_path):
            break
    else:
        print("ERROR: No ONNX model found in download")
        return

    tokenizer_path = os.path.join(model_dir, "tokenizer.json")
    session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    tokenizer = Tokenizer.from_file(tokenizer_path)
    tokenizer.enable_truncation(max_length=2048)

    input_names = [i.name for i in session.get_inputs()]

    def embed(text: str) -> list[float]:
        encoded = tokenizer.encode(text)
        input_ids = np.array([encoded.ids], dtype=np.int64)
        attention_mask = np.array([encoded.attention_mask], dtype=np.int64)

        inputs = {"input_ids": input_ids, "attention_mask": attention_mask}
        if "token_type_ids" in input_names:
            inputs["token_type_ids"] = np.zeros_like(input_ids)

        outputs = session.run(None, inputs)
        # embeddinggemma outputs pooled embedding directly or needs mean pooling
        if outputs[0].ndim == 2:
            pooled = outputs[0][0]
        else:
            token_embeddings = outputs[0]
            mask = attention_mask[0]
            masked = token_embeddings[0] * mask[:, None]
            pooled = masked.sum(axis=0) / mask.sum()

        # Truncate to 768 if MRL
        pooled = pooled[:DIMENSION]
        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_batch(texts: list[str]) -> list[list[float]]:
        return [embed(t) for t in texts]

    run_spike(
        model_name="embeddinggemma-300m",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=622,
    )


if __name__ == "__main__":
    main()
