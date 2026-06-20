"""Spike Model D: snowflake-arctic-embed-m-v2.0 (296MB int8, 768d MRL, 8192 token context)"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def main():
    from tokenizers import Tokenizer
    from onnxruntime import InferenceSession
    from huggingface_hub import hf_hub_download
    import numpy as np

    MODEL_ID = "Teradata/snowflake-arctic-embed-m-v2.0"
    DIMENSION = 768

    print("Downloading model...")
    # Try int8 quantized version first
    try:
        model_path = hf_hub_download(MODEL_ID, "onnx/model_quantized.onnx")
    except Exception:
        model_path = hf_hub_download(MODEL_ID, "onnx/model.onnx")
    tokenizer_path = hf_hub_download(MODEL_ID, "tokenizer.json")

    session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    tokenizer = Tokenizer.from_file(tokenizer_path)
    tokenizer.enable_truncation(max_length=8192)
    tokenizer.enable_padding(pad_id=0, pad_token="[PAD]", length=512)

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

    run_spike(
        model_name="snowflake-arctic-embed-m-v2.0",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=296,
    )


if __name__ == "__main__":
    main()
