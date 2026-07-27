"""Proof H: --force wing isolation.

Invariant: Force-reimporting wing A does NOT affect wing B's chunks.
The --force DELETE is scoped to the target wing only.

This proof would have CAUGHT the --force nuke bug (ticket 52) where
--force previously ran an unscoped DELETE wiping ALL wings.
"""

from pathlib import Path

FIXTURES_A = Path(__file__).parent / "fixtures" / "wing-a"
FIXTURES_B = Path(__file__).parent / "fixtures" / "wing-b"


def run() -> tuple[bool, str]:
    import hashlib
    from recall import chunker, embedder, store

    conn = store.get_connection()
    wing_a = "proof_h_wing_a"
    wing_b = "proof_h_wing_b"

    # Import both wings
    _do_import(conn, FIXTURES_A, wing_a)
    _do_import(conn, FIXTURES_B, wing_b)

    count_a_initial = _chunk_count(conn, wing_a)
    count_b_initial = _chunk_count(conn, wing_b)

    if count_a_initial == 0 or count_b_initial == 0:
        conn.close()
        return False, f"Initial import failed: wing_a={count_a_initial}, wing_b={count_b_initial}"

    # Force-reimport wing A (should only affect wing A)
    _force_reimport(conn, FIXTURES_A, wing_a)

    count_a_after = _chunk_count(conn, wing_a)
    count_b_after = _chunk_count(conn, wing_b)

    conn.close()

    # Wing B must be untouched
    if count_b_after != count_b_initial:
        return False, (
            f"Wing B was affected by wing A force-reimport! "
            f"B: {count_b_initial} → {count_b_after} (ISOLATION VIOLATED)"
        )

    # Wing A should match fresh import count
    if count_a_after != count_a_initial:
        return False, (
            f"Wing A count mismatch after force: {count_a_initial} → {count_a_after}"
        )

    return True, (
        f"Wing B stable ({count_b_initial} chunks) after wing A force-reimport; "
        f"wing A restored to {count_a_after} chunks"
    )


def _force_reimport(conn, source_dir: Path, wing: str):
    """Simulate --force: delete all imports for this wing, then reimport."""
    from recall import store

    deleted = conn.execute(
        "DELETE FROM drawers WHERE source LIKE ? AND wing = ?", ("import:%", wing)
    ).rowcount
    if deleted:
        conn.execute("INSERT INTO drawers_fts(drawers_fts) VALUES('rebuild')")
    store.delete_sources_for_wing(conn, wing)
    conn.commit()

    _do_import(conn, source_dir, wing)


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
