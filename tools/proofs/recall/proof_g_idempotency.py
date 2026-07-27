"""Proof G: Import idempotency (hash-gate skips unchanged files).

Invariant: Importing the same directory twice produces no new chunks on the
second run. The hash-gate detects unchanged content and skips embedding.

This proof would have caught: accumulation bugs where re-imports duplicated
chunks (the original idempotency mechanism relied on source key presence in
drawers; the hash-gate is a stronger guarantee).
"""

from pathlib import Path

FIXTURES = Path(__file__).parent / "fixtures" / "wing-a"


def run() -> tuple[bool, str]:
    from recall import chunker, embedder, store

    conn = store.get_connection()
    wing = "proof_g_wing"

    # First import
    _do_import(conn, FIXTURES, wing)
    count_after_first = _chunk_count(conn, wing)

    if count_after_first == 0:
        conn.close()
        return False, f"First import produced 0 chunks (expected >0)"

    # Second import (identical content)
    _do_import(conn, FIXTURES, wing)
    count_after_second = _chunk_count(conn, wing)

    conn.close()

    if count_after_first != count_after_second:
        return False, (
            f"Chunk count changed: {count_after_first} → {count_after_second} "
            f"(idempotency violated — accumulation detected)"
        )

    return True, f"Stable at {count_after_first} chunks across 2 imports"


def _do_import(conn, source_dir: Path, wing: str):
    """Replicate cmd_import logic for a directory."""
    import hashlib
    from recall import chunker, embedder, store

    md_files = sorted(source_dir.rglob("*.md"))
    md_files = [f for f in md_files if f.name != "index.md"]

    # Detect deleted files
    current_rel_paths = {str(f.relative_to(source_dir)) for f in md_files}
    existing_sources = store.get_sources_for_wing(conn, wing)
    for src in existing_sources:
        if src["path"] not in current_rel_paths:
            source_key = f"import:{wing}:{src['path']}"
            conn.execute("DELETE FROM drawers WHERE source = ?", (source_key,))
            store.delete_source(conn, src["path"], wing)

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
