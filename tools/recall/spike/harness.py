"""
Embedding Spike Harness — shared infrastructure for testing recall embedding models.

Each model spike imports this module and calls:
    run_spike(model_name, embed_fn, embed_batch_fn, dimension)

The harness handles:
- Kiro-CLI JSONL parsing (reuses the normalizer we built)
- Exchange-pair chunking
- SQLite storage with FTS5
- Hybrid BM25 + cosine scoring
- Known-answer query evaluation
- Metrics reporting
"""

import json
import math
import os
import re
import sqlite3
import time
from pathlib import Path
from typing import Callable, Optional

import numpy as np

# ── Config ──────────────────────────────────────────────────────────────────

SESSIONS_DIR = Path.home() / ".kiro" / "sessions" / "cli"
SPIKE_DIR = Path(__file__).parent
CHUNK_SIZE = 800  # chars per drawer

# ── Known-answer queries (ground truth from our MemPalace testing) ──────────

QUERIES = [
    {
        "query": "state machine AI fielder objectives dual role",
        "expected_substring": "objectives can't be \"dumb data\"",
        "description": "Architecture: core tension in fielder system",
    },
    {
        "query": "why did we decide to rebuild from scratch",
        "expected_substring": "ground-up rebuild",
        "description": "Decision: rebuild vs refactor scope",
    },
    {
        "query": "coordinate conversion 2D canvas to 3D world",
        "expected_substring": "0.9144",
        "description": "Technical: yards to meters conversion factor",
    },
    {
        "query": "mirroring should be non-destructive",
        "expected_substring": "non-destructive",
        "description": "Decision: mirroring as transform not data",
    },
    {
        "query": "zero new autoloads for v1",
        "expected_substring": "autoload",
        "description": "Decision: dependency injection over singletons",
    },
]


# ── Kiro-CLI JSONL Parser ───────────────────────────────────────────────────

def parse_kiro_cli_jsonl(content: str) -> Optional[list]:
    """Parse kiro-cli JSONL into [(role, text)] messages."""
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    if not lines:
        return None

    has_kiro = False
    for line in lines[:5]:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(entry, dict) and entry.get("version") == "v1" and entry.get("kind") in ("Prompt", "AssistantMessage", "ToolResults"):
            has_kiro = True
            break

    if not has_kiro:
        return None

    messages = []
    for line in lines:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(entry, dict) or entry.get("version") != "v1":
            continue

        kind = entry.get("kind")
        data = entry.get("data", {})
        if not isinstance(data, dict):
            continue

        if kind == "Prompt":
            parts = []
            for block in data.get("content", []):
                if isinstance(block, dict) and block.get("kind") == "text":
                    t = block.get("data", "").strip()
                    if t:
                        parts.append(t)
            if parts:
                messages.append(("user", "\n".join(parts)))

        elif kind == "AssistantMessage":
            text_parts = []
            for block in data.get("content", []):
                if not isinstance(block, dict):
                    continue
                bk = block.get("kind")
                if bk == "text":
                    t = block.get("data", "").strip()
                    if t:
                        text_parts.append(t)
                elif bk == "toolUse":
                    td = block.get("data", {})
                    name = td.get("name", "unknown")
                    purpose = td.get("input", {}).get("__tool_use_purpose", "")
                    text_parts.append(f"[tool: {name}]" + (f" {purpose}" if purpose else ""))
            combined = "\n".join(text_parts)
            if combined:
                if messages and messages[-1][0] == "assistant":
                    messages[-1] = ("assistant", messages[-1][1] + "\n" + combined)
                else:
                    messages.append(("assistant", combined))

    return messages if len(messages) >= 2 else None


# ── Chunker ─────────────────────────────────────────────────────────────────

def chunk_messages(messages: list) -> list[str]:
    """Chunk message pairs into drawers of ~CHUNK_SIZE chars."""
    chunks = []
    current = []
    current_len = 0

    for role, text in messages:
        prefix = f"> {text}" if role == "user" else text
        if current_len + len(prefix) > CHUNK_SIZE and current:
            chunks.append("\n".join(current))
            current = []
            current_len = 0
        current.append(prefix)
        current_len += len(prefix)

    if current:
        chunks.append("\n".join(current))
    return [c for c in chunks if len(c) > 30]


# ── SQLite Store ────────────────────────────────────────────────────────────

def create_db(db_path: Path, dimension: int) -> sqlite3.Connection:
    """Create a fresh SQLite database with FTS5."""
    if db_path.exists():
        db_path.unlink()
    conn = sqlite3.connect(str(db_path))
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("""
        CREATE TABLE drawers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            embedding BLOB NOT NULL,
            source_file TEXT,
            wing TEXT DEFAULT 'test'
        )
    """)
    conn.execute("""
        CREATE VIRTUAL TABLE drawers_fts USING fts5(content, content='drawers', content_rowid='id')
    """)
    conn.execute("""
        CREATE TRIGGER drawers_ai AFTER INSERT ON drawers BEGIN
            INSERT INTO drawers_fts(rowid, content) VALUES (new.id, new.content);
        END
    """)
    conn.commit()
    return conn


def insert_drawers(conn: sqlite3.Connection, chunks: list[str], embeddings: list, source_file: str):
    """Bulk insert chunks with their embeddings."""
    rows = []
    for chunk, emb in zip(chunks, embeddings):
        blob = np.asarray(emb, dtype=np.float32).tobytes()
        rows.append((chunk, blob, source_file))
    conn.executemany("INSERT INTO drawers (content, embedding, source_file) VALUES (?, ?, ?)", rows)
    conn.commit()


# ── Hybrid Search ───────────────────────────────────────────────────────────

_TOKEN_RE = re.compile(r"\w{2,}", re.UNICODE)


def _tokenize(text: str) -> list[str]:
    return _TOKEN_RE.findall(text.lower()) if text else []


def _bm25_score(query_tokens: list[str], doc_tokens: list[str], avg_dl: float, N: int, df: dict, k1=1.5, b=0.75) -> float:
    dl = len(doc_tokens)
    score = 0.0
    for term in query_tokens:
        if term not in df:
            continue
        n = df[term]
        idf = math.log((N - n + 0.5) / (n + 0.5) + 1.0)
        tf = doc_tokens.count(term)
        numerator = tf * (k1 + 1)
        denominator = tf + k1 * (1 - b + b * dl / avg_dl)
        score += idf * numerator / denominator
    return score


def hybrid_search(conn: sqlite3.Connection, query_embedding: list[float], query_text: str, n_results: int = 5) -> list[dict]:
    """Hybrid BM25 + cosine search."""
    query_vec = np.asarray(query_embedding, dtype=np.float32)

    # Get all drawers
    rows = conn.execute("SELECT id, content, embedding FROM drawers").fetchall()
    if not rows:
        return []

    # Cosine similarity
    results = []
    for row_id, content, emb_blob in rows:
        doc_vec = np.frombuffer(emb_blob, dtype=np.float32)
        cos_sim = float(np.dot(query_vec, doc_vec) / (np.linalg.norm(query_vec) * np.linalg.norm(doc_vec) + 1e-8))
        results.append({"id": row_id, "content": content, "cosine": cos_sim})

    # BM25
    query_tokens = _tokenize(query_text)
    all_doc_tokens = [_tokenize(r["content"]) for r in results]
    N = len(results)
    avg_dl = sum(len(dt) for dt in all_doc_tokens) / max(N, 1)

    # Document frequency
    df = {}
    for dt in all_doc_tokens:
        seen = set(dt)
        for term in seen:
            df[term] = df.get(term, 0) + 1

    for i, r in enumerate(results):
        r["bm25"] = _bm25_score(query_tokens, all_doc_tokens[i], avg_dl, N, df)

    # Combined scoring: normalize and weight
    max_cos = max(r["cosine"] for r in results) or 1.0
    max_bm25 = max(r["bm25"] for r in results) or 1.0

    for r in results:
        cos_norm = r["cosine"] / max_cos
        bm25_norm = r["bm25"] / max_bm25
        r["score"] = 0.7 * cos_norm + 0.3 * bm25_norm

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:n_results]


# ── Spike Runner ────────────────────────────────────────────────────────────

def run_spike(
    model_name: str,
    embed_fn: Callable[[str], list[float]],
    embed_batch_fn: Callable[[list[str]], list[list[float]]],
    dimension: int,
    install_size_mb: float,
):
    """Run the full spike protocol for one model."""
    print(f"\n{'='*60}")
    print(f"  SPIKE: {model_name} ({dimension}d, ~{install_size_mb}MB)")
    print(f"{'='*60}\n")

    db_path = SPIKE_DIR / f"spike_{model_name.replace('/', '_').replace(':', '_')}.sqlite3"
    conn = create_db(db_path, dimension)

    # ── Phase 1: Ingest ─────────────────────────────────────────────
    print("Phase 1: Ingest")
    jsonl_files = sorted(SESSIONS_DIR.glob("*.jsonl"))
    print(f"  Found {len(jsonl_files)} JSONL files")

    total_chunks = 0
    ingest_start = time.time()

    for i, f in enumerate(jsonl_files):
        content = f.read_text(encoding="utf-8", errors="replace")
        messages = parse_kiro_cli_jsonl(content)
        if not messages:
            continue
        chunks = chunk_messages(messages)
        if not chunks:
            continue

        embeddings = embed_batch_fn(chunks)
        insert_drawers(conn, chunks, embeddings, f.name)
        total_chunks += len(chunks)

        if (i + 1) % 20 == 0:
            print(f"  [{i+1}/{len(jsonl_files)}] {total_chunks} chunks so far...")

    ingest_time = time.time() - ingest_start
    print(f"  Done: {total_chunks} chunks in {ingest_time:.1f}s ({total_chunks/max(ingest_time,0.1):.0f} chunks/s)\n")

    # ── Phase 2: Search quality ─────────────────────────────────────
    print("Phase 2: Search quality (recall@3)")
    hits = 0
    latencies = []

    for q in QUERIES:
        t0 = time.time()
        query_emb = embed_fn(q["query"])
        results = hybrid_search(conn, query_emb, q["query"], n_results=3)
        latency = time.time() - t0
        latencies.append(latency)

        found = any(q["expected_substring"].lower() in r["content"].lower() for r in results)
        hits += int(found)
        status = "PASS" if found else "MISS"
        print(f"  {status} {q['description']} ({latency*1000:.0f}ms)")

    recall_at_3 = hits / len(QUERIES)
    p50 = sorted(latencies)[len(latencies)//2]
    p95 = sorted(latencies)[int(len(latencies)*0.95)]

    # ── Phase 3: Report ─────────────────────────────────────────────
    print(f"\n{'-'*60}")
    print(f"  RESULTS: {model_name}")
    print(f"{'-'*60}")
    print(f"  Install size:    ~{install_size_mb} MB")
    print(f"  Dimension:       {dimension}")
    print(f"  Chunks ingested: {total_chunks}")
    print(f"  Ingest time:     {ingest_time:.1f}s")
    print(f"  Ingest rate:     {total_chunks/max(ingest_time,0.1):.0f} chunks/s")
    print(f"  Recall@3:        {hits}/{len(QUERIES)} ({recall_at_3:.0%})")
    print(f"  Query latency:   p50={p50*1000:.0f}ms p95={p95*1000:.0f}ms")
    print(f"{'-'*60}\n")

    # Write results JSON
    results_file = SPIKE_DIR / f"results_{model_name.replace('/', '_').replace(':', '_')}.json"
    results_file.write_text(json.dumps({
        "model": model_name,
        "dimension": dimension,
        "install_size_mb": install_size_mb,
        "chunks_ingested": total_chunks,
        "ingest_time_s": round(ingest_time, 1),
        "ingest_rate_chunks_per_s": round(total_chunks / max(ingest_time, 0.1)),
        "recall_at_3": recall_at_3,
        "recall_hits": hits,
        "recall_total": len(QUERIES),
        "query_latency_p50_ms": round(p50 * 1000),
        "query_latency_p95_ms": round(p95 * 1000),
    }, indent=2))

    conn.close()
    # Clean up DB file
    db_path.unlink(missing_ok=True)

    return recall_at_3
