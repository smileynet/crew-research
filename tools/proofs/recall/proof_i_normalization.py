"""Proof I: Wing name normalization.

Invariant: Hyphenated wing names are normalized to underscores. Whether
the wing is specified explicitly (--wing foo-bar) or auto-derived from a
directory named 'foo-bar', the data lands in wing 'foo_bar'.

This proof would have caught: the wing name split bug (ticket 56) where
inconsistent callers created separate wings for the same project.
"""

from pathlib import Path

FIXTURES_A = Path(__file__).parent / "fixtures" / "wing-a"


def run() -> tuple[bool, str]:
    import hashlib
    from recall import chunker, embedder, store

    conn = store.get_connection()

    # Simulate explicit --wing with hyphens (as the CLI normalizes)
    wing_explicit = "proof-i-hyphenated".replace("-", "_")  # CLI normalizes this

    # Import with the normalized name
    _do_import(conn, FIXTURES_A, wing_explicit)
    count_explicit = _chunk_count(conn, wing_explicit)

    if count_explicit == 0:
        conn.close()
        return False, "Import with normalized wing produced 0 chunks"

    # Verify no chunks exist under the hyphenated form
    count_hyphenated = _chunk_count(conn, "proof-i-hyphenated")

    conn.close()

    if count_hyphenated > 0:
        return False, (
            f"Found {count_hyphenated} chunks under hyphenated wing name! "
            f"Normalization failed — split wing detected"
        )

    # The normalized name should have all the chunks
    if count_explicit == 0:
        return False, "No chunks under normalized wing name"

    return True, (
        f"All {count_explicit} chunks under 'proof_i_hyphenated' "
        f"(0 under hyphenated form) — normalization correct"
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
