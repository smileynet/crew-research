"""Proof K: Search relevance after force-reimport.

Invariant: After force-reimporting a wing, the same search query returns
equivalent content. Chunk IDs may change but the textual content of results
must match (proving no data loss during force cycle).
"""

from pathlib import Path

FIXTURES_A = Path(__file__).parent / "fixtures" / "wing-a"


def run() -> tuple[bool, str]:
    import hashlib
    from recall import chunker, embedder, store

    conn = store.get_connection()
    wing = "proof_k_wing"

    # Initial import
    _do_import(conn, FIXTURES_A, wing)

    # Search and record results
    query = "SQLite storage decision"
    emb = embedder.embed_query(query)
    results_before = store.search(conn, emb, query, wing=wing, n_results=5)
    content_before = sorted(r["content"] for r in results_before)

    if not content_before:
        conn.close()
        return False, "No search results before force-reimport"

    # Force-reimport
    deleted = conn.execute(
        "DELETE FROM drawers WHERE source LIKE ? AND wing = ?", ("import:%", wing)
    ).rowcount
    if deleted:
        conn.execute("INSERT INTO drawers_fts(drawers_fts) VALUES('rebuild')")
    store.delete_sources_for_wing(conn, wing)
    conn.commit()

    _do_import(conn, FIXTURES_A, wing)

    # Search again with same query
    results_after = store.search(conn, emb, query, wing=wing, n_results=5)
    content_after = sorted(r["content"] for r in results_after)

    conn.close()

    if not content_after:
        return False, "No search results after force-reimport (data loss!)"

    # Content should be identical (order may vary but sorted sets match)
    if content_before != content_after:
        return False, (
            f"Content mismatch after force-reimport: "
            f"{len(content_before)} results before vs {len(content_after)} after"
        )

    return True, (
        f"Search results identical after force-reimport "
        f"({len(content_after)} results, same content)"
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
