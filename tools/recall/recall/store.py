"""store.py — SQLite storage with FTS5 + exact cosine hybrid search."""

import json
import math
import re
import sqlite3
import time
from pathlib import Path
from typing import Optional

import numpy as np

DB_PATH = Path.home() / ".recall" / "recall.sqlite3"
_TOKEN_RE = re.compile(r"\w{2,}", re.UNICODE)

SCHEMA_VERSION = 1


def _ensure_db() -> sqlite3.Connection:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("""
        CREATE TABLE IF NOT EXISTS drawers (
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
    conn.execute("""
        CREATE TABLE IF NOT EXISTS meta (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    """)
    conn.execute("INSERT OR IGNORE INTO meta VALUES ('schema_version', ?)", (str(SCHEMA_VERSION),))
    conn.execute("INSERT OR IGNORE INTO meta VALUES ('embedding_model', 'bge-base-en-v1.5-int8')")
    conn.execute("INSERT OR IGNORE INTO meta VALUES ('embedding_dim', '768')")

    # FTS5
    tables = [r[0] for r in conn.execute("SELECT name FROM sqlite_master WHERE type='table'").fetchall()]
    if "drawers_fts" not in tables:
        conn.execute("CREATE VIRTUAL TABLE drawers_fts USING fts5(content, content='drawers', content_rowid='id')")
        conn.execute("""
            CREATE TRIGGER IF NOT EXISTS drawers_ai AFTER INSERT ON drawers BEGIN
                INSERT INTO drawers_fts(rowid, content) VALUES (new.id, new.content);
            END
        """)
        conn.execute("""
            CREATE TRIGGER IF NOT EXISTS drawers_ad AFTER DELETE ON drawers BEGIN
                INSERT INTO drawers_fts(drawers_fts, rowid, content) VALUES ('delete', old.id, old.content);
            END
        """)
    conn.commit()
    return conn


def get_connection() -> sqlite3.Connection:
    return _ensure_db()


def upsert(conn: sqlite3.Connection, content: str, embedding: list[float],
           wing: str, room: str, type_: str, source: str, source_file: Optional[str] = None):
    blob = np.asarray(embedding, dtype=np.float32).tobytes()
    created_at = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    conn.execute(
        "INSERT INTO drawers (content, embedding, wing, room, type, source, source_file, created_at) VALUES (?,?,?,?,?,?,?,?)",
        (content, blob, wing, room, type_, source, source_file, created_at),
    )


def upsert_batch(conn: sqlite3.Connection, rows: list[dict]):
    data = []
    created_at = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    for r in rows:
        blob = np.asarray(r["embedding"], dtype=np.float32).tobytes()
        data.append((r["content"], blob, r["wing"], r["room"], r.get("type", "fact"),
                     r["source"], r.get("source_file"), created_at))
    conn.executemany(
        "INSERT INTO drawers (content, embedding, wing, room, type, source, source_file, created_at) VALUES (?,?,?,?,?,?,?,?)",
        data,
    )
    conn.commit()


def search(conn: sqlite3.Connection, query_embedding: list[float], query_text: str,
           wing: Optional[str] = None, room: Optional[str] = None, n_results: int = 5) -> list[dict]:
    query_vec = np.asarray(query_embedding, dtype=np.float32)

    where = []
    params = []
    if wing:
        where.append("wing = ?")
        params.append(wing)
    if room:
        where.append("room = ?")
        params.append(room)
    where_clause = f"WHERE {' AND '.join(where)}" if where else ""

    rows = conn.execute(f"SELECT id, content, embedding, wing, room, source_file FROM drawers {where_clause}", params).fetchall()
    if not rows:
        return []

    # Cosine similarity
    results = []
    for row_id, content, emb_blob, w, rm, sf in rows:
        doc_vec = np.frombuffer(emb_blob, dtype=np.float32)
        cos_sim = float(np.dot(query_vec, doc_vec) / (np.linalg.norm(query_vec) * np.linalg.norm(doc_vec) + 1e-8))
        results.append({"id": row_id, "content": content, "cosine": cos_sim, "wing": w, "room": rm, "source_file": sf})

    # BM25
    query_tokens = _TOKEN_RE.findall(query_text.lower())
    all_doc_tokens = [_TOKEN_RE.findall(r["content"].lower()) for r in results]
    N = len(results)
    avg_dl = sum(len(dt) for dt in all_doc_tokens) / max(N, 1)

    df = {}
    for dt in all_doc_tokens:
        for term in set(dt):
            df[term] = df.get(term, 0) + 1

    for i, r in enumerate(results):
        dl = len(all_doc_tokens[i])
        score = 0.0
        for term in query_tokens:
            if term not in df:
                continue
            n = df[term]
            idf = math.log((N - n + 0.5) / (n + 0.5) + 1.0)
            tf = all_doc_tokens[i].count(term)
            score += idf * (tf * 2.5) / (tf + 1.5 * (1 - 0.75 + 0.75 * dl / avg_dl))
        r["bm25"] = score

    # Combined scoring
    max_cos = max((r["cosine"] for r in results), default=1.0) or 1.0
    max_bm25 = max((r["bm25"] for r in results), default=1.0) or 1.0

    for r in results:
        r["score"] = 0.7 * (r["cosine"] / max_cos) + 0.3 * (r["bm25"] / max_bm25)

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:n_results]


def get_recent(conn: sqlite3.Connection, wing: Optional[str] = None,
               type_: Optional[str] = None, limit: int = 5) -> list[dict]:
    where = ["source = 'agent-write'"]
    params = []
    if wing:
        where.append("wing = ?")
        params.append(wing)
    if type_:
        where.append("type = ?")
        params.append(type_)
    rows = conn.execute(
        f"SELECT content, wing, room, type, created_at FROM drawers WHERE {' AND '.join(where)} ORDER BY created_at DESC LIMIT ?",
        params + [limit],
    ).fetchall()
    return [{"content": r[0], "wing": r[1], "room": r[2], "type": r[3], "created_at": r[4]} for r in rows]


def status(conn: sqlite3.Connection) -> dict:
    total = conn.execute("SELECT COUNT(*) FROM drawers").fetchone()[0]
    wings = conn.execute("SELECT wing, room, COUNT(*) FROM drawers GROUP BY wing, room ORDER BY wing, COUNT(*) DESC").fetchall()
    breakdown = {}
    for w, r, c in wings:
        breakdown.setdefault(w, {})[r] = c
    return {"total": total, "wings": breakdown}


def is_file_ingested(conn: sqlite3.Connection, source_file: str) -> bool:
    row = conn.execute("SELECT 1 FROM drawers WHERE source_file = ? LIMIT 1", (source_file,)).fetchone()
    return row is not None
