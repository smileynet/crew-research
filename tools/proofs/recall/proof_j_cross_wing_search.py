"""Proof J: Cross-wing search.

Invariant: Searching without --wing returns results from ALL wings.
Content imported into separate wings is discoverable via unscoped queries.
"""

from pathlib import Path

FIXTURES_A = Path(__file__).parent / "fixtures" / "wing-a"
FIXTURES_B = Path(__file__).parent / "fixtures" / "wing-b"


def run() -> tuple[bool, str]:
    import hashlib
    from recall import chunker, embedder, store

    conn = store.get_connection()
    wing_a = "proof_j_wing_a"
    wing_b = "proof_j_wing_b"

    # Import both wings
    _do_import(conn, FIXTURES_A, wing_a)
    _do_import(conn, FIXTURES_B, wing_b)

    # Search without wing filter for a term unique to wing-a
    query_a = "SQLite FTS5 storage"
    emb_a = embedder.embed_query(query_a)
    results_a = store.search(conn, emb_a, query_a, n_results=10)

    # Search for a term unique to wing-b
    query_b = "deployment pipeline canary"
    emb_b = embedder.embed_query(query_b)
    results_b = store.search(conn, emb_b, query_b, n_results=10)

    conn.close()

    # Verify wing-a content appears in unscoped search
    wings_in_a_results = {r["wing"] for r in results_a}
    wings_in_b_results = {r["wing"] for r in results_b}

    if wing_a not in wings_in_a_results:
        return False, f"Wing A content not found in unscoped search for '{query_a}'"

    if wing_b not in wings_in_b_results:
        return False, f"Wing B content not found in unscoped search for '{query_b}'"

    return True, (
        f"Cross-wing search works: '{query_a}' found in {wings_in_a_results}, "
        f"'{query_b}' found in {wings_in_b_results}"
    )


def _do_import(conn, source_dir: Path, wing: str):
    """Import markdown files with hash-gate."""
    import hashlib
    from recall import chunker, embedder, store

    md_files = sorted(source_dir.rglob("*.md"))
    md_files = [f for f in md_files if f.name != "index.md"]

    for md_file in md_files:
        rel_path = str(md_file.relative_to(source_dir))
        source_key = f"import:{wing}:{rel_path}"

        text = md_file.read_text(encoding="utf-8", errors="replace")
        if not text.strip():
            continue

        content_hash = hashlib.sha256(text.encode("utf-8")).hexdigest()
        file_size = len(text.encode("utf-8"))

        stored_hash = store.get_source_hash(conn, rel_path, wing)
        if stored_hash == content_hash:
            continue

        if stored_hash is not None:
            conn.execute("DELETE FROM drawers WHERE source = ?", (source_key,))

        chunks = chunker.chunk_markdown(text)
        if not chunks:
            store.upsert_source(conn, rel_path, wing, content_hash, file_size, 0)
            conn.commit()
            continue

        parts = list(Path(rel_path).parts)
        room = parts[0] if len(parts) > 1 else "general"

        embeddings = embedder.embed_documents(chunks)
        rows = []
        for chunk, emb in zip(chunks, embeddings):
            rows.append({
                "content": chunk, "embedding": emb, "wing": wing,
                "room": room, "type": "document", "source": source_key,
                "source_file": rel_path,
            })

        store.upsert_batch(conn, rows)
        store.upsert_source(conn, rel_path, wing, content_hash, file_size, len(chunks))
        conn.commit()


def _chunk_count(conn, wing: str) -> int:
    row = conn.execute("SELECT COUNT(*) FROM drawers WHERE wing = ?", (wing,)).fetchone()
    return row[0]
