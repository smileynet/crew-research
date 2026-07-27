"""Shared fixtures for recall unit tests."""

import os
import sqlite3
import tempfile
from pathlib import Path
from unittest.mock import patch

import numpy as np
import pytest

EMBEDDING_DIM = 768


@pytest.fixture
def mock_embedder(monkeypatch):
    """Mock the embedder to return deterministic random vectors.

    Avoids loading the ONNX model (~2s) for unit tests.
    Uses a seeded RNG so results are reproducible.
    """
    rng = np.random.default_rng(42)

    def _embed_documents(texts):
        return [rng.random(EMBEDDING_DIM, dtype=np.float32).tolist() for _ in texts]

    def _embed_query(text):
        return rng.random(EMBEDDING_DIM, dtype=np.float32).tolist()

    def _embed_document(text):
        return rng.random(EMBEDDING_DIM, dtype=np.float32).tolist()

    monkeypatch.setattr("recall.embedder.embed_documents", _embed_documents)
    monkeypatch.setattr("recall.embedder.embed_query", _embed_query)
    monkeypatch.setattr("recall.embedder.embed_document", _embed_document)


@pytest.fixture
def tmp_db(tmp_path):
    """Create a temporary database file and point RECALL_DB at it.

    Yields the path. Automatically cleans up after test.
    """
    db_path = str(tmp_path / "test-recall.sqlite3")
    os.environ["RECALL_DB"] = db_path

    # Force store module to pick up new path
    import recall.store as store_mod
    store_mod.DB_PATH = Path(db_path)

    yield db_path

    os.environ.pop("RECALL_DB", None)


@pytest.fixture
def db_conn(tmp_db):
    """Get a connection to the temp DB (schema already initialized)."""
    from recall.store import get_connection
    conn = get_connection()
    yield conn
    conn.close()


@pytest.fixture
def sample_memory_dir(tmp_path):
    """Create a sample .memory/ directory with markdown files for import testing."""
    mem_dir = tmp_path / "project" / ".memory"
    mem_dir.mkdir(parents=True)

    (mem_dir / "CONTEXT.md").write_text(
        "---\ntype: glossary\ntitle: Context\n---\n\n# Context\n\n"
        "**widget**:\nA reusable UI component.\n_Avoid_: element\n",
        encoding="utf-8",
    )

    adr_dir = mem_dir / "adr"
    adr_dir.mkdir()
    (adr_dir / "0001-use-sqlite.md").write_text(
        "---\ntype: decision\ntitle: ADR 0001\n---\n\n# Use SQLite\n\n"
        "## Decision\n\nWe chose SQLite for local storage because it requires no server.\n",
        encoding="utf-8",
    )

    return mem_dir
