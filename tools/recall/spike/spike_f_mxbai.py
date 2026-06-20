"""Spike Model F: mxbai-embed-large (670MB, 1024d, 512 token context)"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def main():
    from tokenizers import Tokenizer
    from onnxruntime import InferenceSession
    from huggingface_hub import hf_hub_download
    import numpy as np

    MODEL_ID = "mixedbread-ai/mxbai-embed-large-v1"
    DIMENSION = 1024

    print("Downloading model...")
    model_path = hf_hub_download(MODEL_ID, "onnx/model.onnx")
    tokenizer_path = hf_hub_download(MODEL_ID, "tokenizer.json")

    session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    tokenizer = Tokenizer.from_file(tokenizer_path)
    tokenizer.enable_truncation(max_length=512)
    tokenizer.enable_padding(pad_id=0, pad_token="[PAD]", length=512)

    input_names = [i.name for i in session.get_inputs()]

    def embed(text: str) -> list[float]:
        # mxbai requires query prefix for retrieval
        prefixed = "Represent this sentence for searching relevant passages: " + text
        encoded = tokenizer.encode(prefixed)
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

        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_doc(text: str) -> list[float]:
        # Documents embedded without prefix
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

        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_batch(texts: list[str]) -> list[list[float]]:
        return [embed_doc(t) for t in texts]

    run_spike(
        model_name="mxbai-embed-large-v1",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=670,
    )


if __name__ == "__main__":
    main()
