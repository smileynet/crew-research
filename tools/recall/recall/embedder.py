"""embedder.py — bge-base-en-v1.5 int8 ONNX embedding."""

from pathlib import Path
from typing import Optional

import numpy as np

_SESSION = None
_TOKENIZER = None

MODEL_ID = "Xenova/bge-base-en-v1.5"
DIMENSION = 768
QUERY_PREFIX = "Represent this sentence for searching relevant passages: "


def _load():
    global _SESSION, _TOKENIZER
    if _SESSION is not None:
        return

    from huggingface_hub import hf_hub_download
    from onnxruntime import InferenceSession
    from tokenizers import Tokenizer

    model_path = hf_hub_download(MODEL_ID, "onnx/model_quantized.onnx")
    tokenizer_path = hf_hub_download(MODEL_ID, "tokenizer.json")

    _SESSION = InferenceSession(model_path, providers=["CPUExecutionProvider"])
    _TOKENIZER = Tokenizer.from_file(tokenizer_path)
    _TOKENIZER.enable_truncation(max_length=512)
    _TOKENIZER.enable_padding(pad_id=0, pad_token="[PAD]", length=512)


def _embed_raw(text: str) -> np.ndarray:
    _load()
    encoded = _TOKENIZER.encode(text)
    input_ids = np.array([encoded.ids], dtype=np.int64)
    attention_mask = np.array([encoded.attention_mask], dtype=np.int64)

    inputs = {"input_ids": input_ids, "attention_mask": attention_mask}
    input_names = [i.name for i in _SESSION.get_inputs()]
    if "token_type_ids" in input_names:
        inputs["token_type_ids"] = np.zeros_like(input_ids)

    outputs = _SESSION.run(None, inputs)
    pooled = outputs[0][0][0]  # CLS token
    norm = np.linalg.norm(pooled)
    return pooled / norm


def embed_query(text: str) -> list[float]:
    return _embed_raw(QUERY_PREFIX + text).tolist()


def embed_document(text: str) -> list[float]:
    return _embed_raw(text).tolist()


def embed_documents(texts: list[str]) -> list[list[float]]:
    return [embed_document(t) for t in texts]
