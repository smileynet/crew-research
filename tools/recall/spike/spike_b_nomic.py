"""Spike Model B: nomic-embed-text v1.5 (274MB, 768d MRL, 8192 token context)"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from harness import run_spike


def main():
    from tokenizers import Tokenizer
    from onnxruntime import InferenceSession
    from huggingface_hub import hf_hub_download
    import numpy as np

    MODEL_ID = "nomic-ai/nomic-embed-text-v1.5"
    DIMENSION = 768

    print("Downloading model...")
    model_path = hf_hub_download(MODEL_ID, "onnx/model.onnx")
    tokenizer_path = hf_hub_download(MODEL_ID, "tokenizer.json")

    session = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    tokenizer = Tokenizer.from_file(tokenizer_path)
    tokenizer.enable_truncation(max_length=8192)
    tokenizer.enable_padding(pad_id=0, pad_token="[PAD]", length=512)  # pad to reasonable length

    def embed(text: str) -> list[float]:
        # nomic requires task prefix for retrieval
        prefixed = "search_query: " + text
        encoded = tokenizer.encode(prefixed)
        input_ids = np.array([encoded.ids], dtype=np.int64)
        attention_mask = np.array([encoded.attention_mask], dtype=np.int64)

        inputs = {"input_ids": input_ids, "attention_mask": attention_mask}
        # Add token_type_ids if model expects it
        input_names = [i.name for i in session.get_inputs()]
        if "token_type_ids" in input_names:
            inputs["token_type_ids"] = np.zeros_like(input_ids)

        outputs = session.run(None, inputs)
        token_embeddings = outputs[0]
        mask = attention_mask[0]
        masked = token_embeddings[0] * mask[:, None]
        pooled = masked.sum(axis=0) / mask.sum()
        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_doc(text: str) -> list[float]:
        # Documents get different prefix
        prefixed = "search_document: " + text
        encoded = tokenizer.encode(prefixed)
        input_ids = np.array([encoded.ids], dtype=np.int64)
        attention_mask = np.array([encoded.attention_mask], dtype=np.int64)

        inputs = {"input_ids": input_ids, "attention_mask": attention_mask}
        input_names = [i.name for i in session.get_inputs()]
        if "token_type_ids" in input_names:
            inputs["token_type_ids"] = np.zeros_like(input_ids)

        outputs = session.run(None, inputs)
        token_embeddings = outputs[0]
        mask = attention_mask[0]
        masked = token_embeddings[0] * mask[:, None]
        pooled = masked.sum(axis=0) / mask.sum()
        norm = np.linalg.norm(pooled)
        return (pooled / norm).tolist()

    def embed_batch(texts: list[str]) -> list[list[float]]:
        return [embed_doc(t) for t in texts]

    run_spike(
        model_name="nomic-embed-text-v1.5",
        embed_fn=embed,
        embed_batch_fn=embed_batch,
        dimension=DIMENSION,
        install_size_mb=274,
    )


if __name__ == "__main__":
    main()
