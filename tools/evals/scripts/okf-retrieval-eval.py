#!/usr/bin/env python3
"""okf-retrieval-eval.py — 2-condition retrieval eval for recall import.

Condition 1 (baseline): sessions-only recall search
Condition 2 (+memory): sessions + imported .memory/ files

Compares recall@1, recall@3, MRR across 8 queries with known expected sources.
"""

import json
import os
import sys
import tempfile
from pathlib import Path

# Add recall tool to path
RECALL_DIR = Path(__file__).resolve().parent.parent.parent / "recall"
sys.path.insert(0, str(RECALL_DIR))

from recall import chunker, embedder, normalize, store

PROJECT_DIR = Path(__file__).resolve().parent.parent.parent.parent
MEMORY_DIR = PROJECT_DIR / ".memory"
SESSIONS_DIR = Path.home() / ".kiro" / "sessions"

# The workspace hash for crew-research sessions
CREW_RESEARCH_WORKSPACE = "72cb6b3fe78dab52"

QUERIES = [
    {
        "query": "What was decided about the recall tool implementation?",
        "expected_source": "adr/0007-purpose-built-recall-tool.md",
        "category": "decision-lookup",
    },
    {
        "query": "How does the eval harness work?",
        "expected_source": "specs/eval-harness.md",
        "category": "system",
    },
    {
        "query": "What does progressive loading mean in this project?",
        "expected_source": "CONTEXT.md",
        "category": "term-lookup",
    },
    {
        "query": "Why did we choose three tiers instead of two?",
        "expected_source": "adr/0005-three-tier-deployment.md",
        "category": "decision-lookup",
    },
    {
        "query": "How are skills deployed to different tools?",
        "expected_source": "specs/tool-adapters.md",
        "category": "system",
    },
    {
        "query": "What is the relationship between practices and skills?",
        "expected_source": "specs/practice-skill-crosslinks.md",
        "category": "relationship",
    },
    {
        "query": "How does multi-turn evaluation work?",
        "expected_source": "specs/multi-turn-eval-findings.md",
        "category": "system",
    },
    {
        "query": "What customization options exist for per-project skills?",
        "expected_source": "adr/0002-per-project-customization.md",
        "category": "decision-lookup",
    },
]


def ingest_sessions(conn: "sqlite3.Connection") -> int:
    """Ingest crew-research sessions into the given connection's DB."""
    workspace_dir = SESSIONS_DIR / CREW_RESEARCH_WORKSPACE
    if not workspace_dir.is_dir():
        print(f"  Warning: workspace dir not found: {workspace_dir}", file=sys.stderr)
        return 0

    keywords = chunker.load_topic_keywords()
    total_chunks = 0

    for sess_dir in sorted(workspace_dir.iterdir()):
        if not sess_dir.is_dir() or not sess_dir.name.startswith("sess_"):
            continue
        messages_file = sess_dir / "messages.jsonl"
        if not messages_file.exists():
            continue

        messages = normalize.detect_and_parse(messages_file)
        if not messages:
            continue

        chunks = chunker.chunk_messages(messages)
        if not chunks:
            continue

        embeddings = embedder.embed_documents(chunks)
        rows = []
        for chunk, emb in zip(chunks, embeddings):
            room = chunker.classify_room(chunk, keywords)
            rows.append({
                "content": chunk,
                "embedding": emb,
                "wing": "crew_research",
                "room": room,
                "source": f"ingest:{sess_dir.name}",
                "source_file": sess_dir.name,
            })

        store.upsert_batch(conn, rows)
        total_chunks += len(chunks)

    return total_chunks


def import_memory(conn: "sqlite3.Connection") -> int:
    """Import .memory/ markdown files into the given connection's DB.

    Uses the production chunk_markdown() implementation.
    """
    total_chunks = 0

    for md_file in sorted(MEMORY_DIR.rglob("*.md")):
        if md_file.name == "index.md":
            continue

        rel_path = md_file.relative_to(MEMORY_DIR)
        source_key = f"import:{rel_path}"

        # Check idempotency
        row = conn.execute(
            "SELECT 1 FROM drawers WHERE source = ? LIMIT 1", (source_key,)
        ).fetchone()
        if row:
            continue

        text = md_file.read_text(encoding="utf-8", errors="replace")
        if not text.strip():
            continue

        # Chunk using production chunker
        chunks = chunker.chunk_markdown(text)
        if not chunks:
            continue

        # Derive wing/room from path
        parts = list(rel_path.parts)
        room = parts[0] if len(parts) > 1 else "general"

        embeddings = embedder.embed_documents(chunks)
        rows = []
        for chunk, emb in zip(chunks, embeddings):
            rows.append({
                "content": chunk,
                "embedding": emb,
                "wing": "crew_research",
                "room": room,
                "type": "document",
                "source": source_key,
                "source_file": str(rel_path),
            })

        store.upsert_batch(conn, rows)
        total_chunks += len(chunks)

    return total_chunks


def run_queries(conn: "sqlite3.Connection") -> dict:
    """Run all 8 queries and compute recall@1, recall@3, MRR."""
    hits_at_1 = 0
    hits_at_3 = 0
    rr_sum = 0.0

    details = []

    for q in QUERIES:
        query_emb = embedder.embed_query(q["query"])
        results = store.search(conn, query_emb, q["query"], wing="crew_research", n_results=5)

        # Check source_file matches
        found_at = None
        for i, r in enumerate(results):
            sf = r.get("source_file", "")
            if sf and q["expected_source"] in sf:
                found_at = i + 1  # 1-indexed
                break

        if found_at == 1:
            hits_at_1 += 1
        if found_at and found_at <= 3:
            hits_at_3 += 1
        if found_at and found_at <= 5:
            rr_sum += 1.0 / found_at

        details.append({
            "query": q["query"],
            "expected": q["expected_source"],
            "found_at": found_at,
            "top_3_sources": [r.get("source_file", "?") for r in results[:3]],
        })

    n = len(QUERIES)
    return {
        "recall_at_1": hits_at_1 / n,
        "recall_at_3": hits_at_3 / n,
        "mrr": rr_sum / n,
        "details": details,
    }


def run_condition(label: str, include_memory: bool) -> dict:
    """Run one eval condition with an isolated temp DB."""
    with tempfile.NamedTemporaryFile(suffix=".sqlite3", delete=False, prefix=f"recall-eval-{label}-") as f:
        db_path = Path(f.name)

    # Override the store's DB_PATH
    os.environ["RECALL_DB"] = str(db_path)
    # Force store to use new path by reimporting connection
    import importlib
    importlib.reload(store)

    try:
        conn = store.get_connection()

        print(f"  [{label}] Ingesting sessions...", file=sys.stderr)
        session_chunks = ingest_sessions(conn)
        print(f"  [{label}] Sessions: {session_chunks} chunks", file=sys.stderr)

        if include_memory:
            print(f"  [{label}] Importing .memory/...", file=sys.stderr)
            memory_chunks = import_memory(conn)
            print(f"  [{label}] Memory: {memory_chunks} chunks", file=sys.stderr)

        total = conn.execute("SELECT COUNT(*) FROM drawers").fetchone()[0]
        print(f"  [{label}] Total drawers: {total}", file=sys.stderr)

        results = run_queries(conn)
        conn.close()
        return results
    finally:
        # Cleanup temp DB
        db_path.unlink(missing_ok=True)
        wal = db_path.with_suffix(".sqlite3-wal")
        shm = db_path.with_suffix(".sqlite3-shm")
        wal.unlink(missing_ok=True)
        shm.unlink(missing_ok=True)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="OKF retrieval eval")
    parser.add_argument("--condition", choices=["baseline", "memory", "both"], default="both",
                        help="Which condition(s) to run")
    parser.add_argument("--verbose", action="store_true", help="Print per-query details")
    args = parser.parse_args()

    results = {}

    if args.condition in ("baseline", "both"):
        print("\n=== Condition 1: sessions-only ===", file=sys.stderr)
        results["sessions-only"] = run_condition("sessions-only", include_memory=False)

    if args.condition in ("memory", "both"):
        print("\n=== Condition 2: sessions + .memory/ ===", file=sys.stderr)
        results["sessions-plus-memory"] = run_condition("sessions-plus-memory", include_memory=True)

    # Build output
    output = {"conditions": {}}
    for label, r in results.items():
        output["conditions"][label] = {
            "recall_at_1": r["recall_at_1"],
            "recall_at_3": r["recall_at_3"],
            "mrr": r["mrr"],
        }
        if args.verbose:
            output["conditions"][label]["details"] = r["details"]

    if "sessions-only" in results and "sessions-plus-memory" in results:
        baseline = results["sessions-only"]["recall_at_3"]
        improved = results["sessions-plus-memory"]["recall_at_3"]
        delta = improved - baseline
        output["improvement"] = {"recall_at_3_delta": delta}
        output["verdict"] = "PASS" if delta >= 0.20 else "FAIL"
        output["threshold"] = "recall@3 delta >= 0.20"

    print(json.dumps(output, indent=2))

    # Exit code
    if output.get("verdict") == "FAIL":
        sys.exit(1)


if __name__ == "__main__":
    main()
