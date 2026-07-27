"""Tests for recall.store — schema migrations and sources table operations."""

import sqlite3
import time

import numpy as np
import pytest


def test_fresh_db_creates_schema(tmp_db):
    """A fresh DB should have all tables at schema v4."""
    from recall.store import get_connection

    conn = get_connection()
    tables = {r[0] for r in conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()}
    conn.close()

    assert "drawers" in tables
    assert "meta" in tables
    assert "sources" in tables
    assert "drawers_fts" in tables


def test_schema_version_is_4(tmp_db):
    """Fresh DB should be at schema version 4."""
    from recall.store import get_connection

    conn = get_connection()
    version = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()[0]
    conn.close()

    assert version == "4"


def test_migration_v1_to_v4(tmp_path):
    """Simulate a v1 database and verify migration to v4."""
    import os
    from pathlib import Path

    db_path = str(tmp_path / "migrate-test.sqlite3")
    os.environ["RECALL_DB"] = db_path

    # Create a minimal v1 database manually
    conn = sqlite3.connect(db_path)
    conn.execute("""
        CREATE TABLE drawers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            embedding BLOB NOT NULL,
            wing TEXT NOT NULL,
            room TEXT NOT NULL DEFAULT 'general',
            type TEXT NOT NULL DEFAULT 'fact',
            source TEXT NOT NULL,
            source_file TEXT,
            created_at TEXT NOT NULL
        )
    """)
    conn.execute("CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT)")
    conn.execute("INSERT INTO meta VALUES ('schema_version', '1')")
    conn.execute("INSERT INTO meta VALUES ('embedding_model', 'bge-base-en-v1.5-int8')")
    conn.execute("INSERT INTO meta VALUES ('embedding_dim', '768')")

    # Insert a v1-style import row (old source key format without wing prefix)
    emb = np.zeros(768, dtype=np.float32).tobytes()
    conn.execute(
        "INSERT INTO drawers (content, embedding, wing, room, type, source, created_at) VALUES (?,?,?,?,?,?,?)",
        ("test content", emb, "my_project", "general", "document", "import:CONTEXT.md", "2026-01-01T00:00:00")
    )
    conn.commit()
    conn.close()

    # Now load via recall.store — should trigger migrations
    import recall.store as store_mod
    store_mod.DB_PATH = Path(db_path)
    conn = store_mod.get_connection()

    # Check version is now 4
    version = conn.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()[0]
    assert version == "4"

    # Check v2 migration: title column exists
    cols = [r[1] for r in conn.execute("PRAGMA table_info(drawers)").fetchall()]
    assert "title" in cols

    # Check v3 migration: source key has wing prefix
    source = conn.execute("SELECT source FROM drawers WHERE wing='my_project'").fetchone()[0]
    assert source == "import:my_project:CONTEXT.md"

    # Check v4: sources table exists
    tables = {r[0] for r in conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table'"
    ).fetchall()}
    assert "sources" in tables

    conn.close()
    os.environ.pop("RECALL_DB", None)


def test_upsert_source(db_conn):
    """Test insert and update of sources manifest entries."""
    from recall.store import get_source_hash, upsert_source

    upsert_source(db_conn, "CONTEXT.md", "test_wing", "abc123", 1024, 5)
    db_conn.commit()

    assert get_source_hash(db_conn, "CONTEXT.md", "test_wing") == "abc123"

    # Update with new hash
    upsert_source(db_conn, "CONTEXT.md", "test_wing", "def456", 2048, 8)
    db_conn.commit()

    assert get_source_hash(db_conn, "CONTEXT.md", "test_wing") == "def456"


def test_get_sources_for_wing(db_conn):
    """Test retrieving all sources for a wing."""
    from recall.store import get_sources_for_wing, upsert_source

    upsert_source(db_conn, "file1.md", "wing_a", "hash1", 100, 3)
    upsert_source(db_conn, "file2.md", "wing_a", "hash2", 200, 5)
    upsert_source(db_conn, "file3.md", "wing_b", "hash3", 300, 2)
    db_conn.commit()

    sources = get_sources_for_wing(db_conn, "wing_a")
    assert len(sources) == 2
    paths = {s["path"] for s in sources}
    assert paths == {"file1.md", "file2.md"}


def test_delete_source(db_conn):
    """Test removing a single source entry."""
    from recall.store import delete_source, get_source_hash, upsert_source

    upsert_source(db_conn, "file.md", "wing", "hash", 100, 1)
    db_conn.commit()
    assert get_source_hash(db_conn, "file.md", "wing") is not None

    delete_source(db_conn, "file.md", "wing")
    db_conn.commit()
    assert get_source_hash(db_conn, "file.md", "wing") is None


def test_delete_sources_for_wing(db_conn):
    """Test removing all sources for a wing."""
    from recall.store import delete_sources_for_wing, get_sources_for_wing, upsert_source

    upsert_source(db_conn, "f1.md", "wing_x", "h1", 100, 1)
    upsert_source(db_conn, "f2.md", "wing_x", "h2", 200, 2)
    upsert_source(db_conn, "f3.md", "wing_y", "h3", 300, 3)
    db_conn.commit()

    count = delete_sources_for_wing(db_conn, "wing_x")
    db_conn.commit()

    assert count == 2
    assert get_sources_for_wing(db_conn, "wing_x") == []
    assert len(get_sources_for_wing(db_conn, "wing_y")) == 1


def test_source_isolation_between_wings(db_conn):
    """Same path in different wings should be independent entries."""
    from recall.store import get_source_hash, upsert_source

    upsert_source(db_conn, "CONTEXT.md", "project_a", "hash_a", 100, 3)
    upsert_source(db_conn, "CONTEXT.md", "project_b", "hash_b", 200, 5)
    db_conn.commit()

    assert get_source_hash(db_conn, "CONTEXT.md", "project_a") == "hash_a"
    assert get_source_hash(db_conn, "CONTEXT.md", "project_b") == "hash_b"
