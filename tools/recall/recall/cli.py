"""cli.py — recall CLI: search, add, ingest, prime, status."""

import argparse
import os
import sys
import time
from pathlib import Path

# Suppress HuggingFace auth warnings
os.environ.setdefault("HF_HUB_VERBOSITY", "error")

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(errors="replace")
    sys.stderr.reconfigure(errors="replace")


def cmd_search(args):
    from . import embedder, store

    conn = store.get_connection()
    query_emb = embedder.embed_query(args.query)
    results = store.search(conn, query_emb, args.query, wing=args.wing, room=args.room, n_results=args.results)
    conn.close()

    if not results:
        print("No results found.")
        return

    print(f"\n  Results for: \"{args.query}\"")
    if args.wing:
        print(f"  Wing: {args.wing}")
    if args.room:
        print(f"  Room: {args.room}")
    print()

    for i, r in enumerate(results, 1):
        print(f"  [{i}] {r['wing']} / {r['room']}")
        if r.get("source_file"):
            print(f"      Source: {r['source_file']}")
        print(f"      Score: {r['score']:.3f} (cos={r['cosine']:.3f} bm25={r['bm25']:.1f})")
        print()
        preview = r["content"][:300].replace("\n", "\n      ")
        print(f"      {preview}")
        if len(r["content"]) > 300:
            print(f"      ... ({len(r['content'])} chars total)")
        print()


def cmd_add(args):
    from . import embedder, store

    if len(args.text) > 2000:
        print(f"Error: text too long ({len(args.text)} chars, max 2000). Distill before storing.", file=sys.stderr)
        sys.exit(1)

    conn = store.get_connection()
    emb = embedder.embed_document(args.text)
    store.upsert(conn, args.text, emb, wing=args.wing or "global", room=args.room or "general",
                 type_=args.type or "fact", source="agent-write")
    conn.commit()
    conn.close()
    print(f"Stored: [{args.type or 'fact'}] {args.text[:80]}...")


def cmd_ingest(args):
    from . import chunker, embedder, normalize, store

    source_dir = Path(args.path).expanduser().resolve()
    if not source_dir.is_dir():
        print(f"Error: {source_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    conn = store.get_connection()
    keywords = chunker.load_topic_keywords()

    # Discover JSONL files: v2 (flat *.jsonl) + v3 (*/sess_*/messages.jsonl)
    jsonl_files = sorted(source_dir.glob("*.jsonl"))
    v3_files = sorted(source_dir.glob("*/sess_*/messages.jsonl"))
    all_files = jsonl_files + v3_files

    if args.project:
        project_path = Path(args.project).expanduser().resolve()
        project_name = project_path.name.replace("-", "_")
    else:
        project_path = None
        project_name = None

    total_chunks = 0
    files_processed = 0
    files_skipped = 0

    print(f"\n  Ingesting: {source_dir}")
    print(f"  Files: {len(all_files)} JSONL ({len(jsonl_files)} v2, {len(v3_files)} v3)")
    print()

    for i, f in enumerate(all_files):
        if store.is_file_ingested(conn, f.name if f.name != "messages.jsonl" else f.parent.name):
            files_skipped += 1
            continue

        # Determine wing from session metadata
        wing = "global"
        is_v3 = (f.name == "messages.jsonl")
        if is_v3:
            session_id = f.parent.name  # sess_<uuid>
            cwd = normalize.extract_cwd_from_session(f.parent, session_id)
        else:
            session_id = f.stem
            cwd = normalize.extract_cwd_from_session(source_dir, session_id)
        if project_name:
            wing = project_name
        elif cwd:
            wing = Path(cwd).name.replace("-", "_")

        # Filter by project if specified
        if project_path and cwd and Path(cwd).resolve() != project_path:
            continue

        messages = normalize.detect_and_parse(f)
        if not messages:
            continue

        chunks = chunker.chunk_messages(messages)
        if not chunks:
            continue

        embeddings = embedder.embed_documents(chunks)
        source_label = f.parent.name if is_v3 else f.name
        rows = []
        for chunk, emb in zip(chunks, embeddings):
            room = chunker.classify_room(chunk, keywords)
            rows.append({"content": chunk, "embedding": emb, "wing": wing, "room": room, "source": f"ingest:{source_label}", "source_file": source_label})

        store.upsert_batch(conn, rows)
        total_chunks += len(chunks)
        files_processed += 1

        if (files_processed) % 10 == 0:
            print(f"  [{files_processed}] {total_chunks} chunks...")

    conn.close()
    print(f"\n  Done: {files_processed} files, {total_chunks} chunks ingested, {files_skipped} skipped (already filed)")

    # Write last-run marker
    marker = Path.home() / ".recall" / "last_ingest"
    marker.write_text(str(int(time.time())))


def cmd_prime(args):
    from . import embedder, store

    conn = store.get_connection()
    wing = args.wing

    # Instructions
    print("## Recall - Cross-Session Memory")
    print()
    print("Use `recall search \"query\"` before answering questions about past decisions.")
    print("Use `recall add \"fact\" --wing X --room Y --type decision` to persist learnings.")
    print()

    # Recent agent-written memories
    recent = store.get_recent(conn, wing=wing, limit=7)
    if recent:
        print(f"## Recent Memories{f' ({wing})' if wing else ''}")
        print()
        for r in recent:
            print(f"- [{r['type']}] {r['content'][:120]} ({r['created_at'][:10]})")
        print()

    # Top retrieval for the wing
    if wing:
        query_emb = embedder.embed_query(f"important decisions and architecture for {wing}")
        results = store.search(conn, query_emb, f"decisions architecture {wing}", wing=wing, n_results=3)
        if results:
            print("## Relevant Context")
            print()
            for r in results:
                preview = r["content"][:200].replace("\n", "\n  ")
                print(f"  {preview}")
                if r.get("source_file"):
                    print(f"  (source: {r['source_file']})")
                print()

    conn.close()


def cmd_status(args):
    from . import store

    conn = store.get_connection()
    s = store.status(conn)
    conn.close()

    print(f"\n  Recall — {s['total']} drawers")
    print()
    for wing, rooms in s["wings"].items():
        total_wing = sum(rooms.values())
        print(f"  WING: {wing} ({total_wing})")
        for room, count in rooms.items():
            print(f"    {room}: {count}")
    print()


def main():
    parser = argparse.ArgumentParser(prog="recall", description="Cross-session semantic memory for AI agents")
    parser.add_argument("--version", action="version", version="recall 0.1.0")
    sub = parser.add_subparsers(dest="command")

    # search
    p = sub.add_parser("search", help="Semantic search")
    p.add_argument("query")
    p.add_argument("--wing", default=None)
    p.add_argument("--room", default=None)
    p.add_argument("--results", type=int, default=5)

    # add
    p = sub.add_parser("add", help="Store a fact/decision/lesson")
    p.add_argument("text")
    p.add_argument("--wing", default=None)
    p.add_argument("--room", default=None)
    p.add_argument("--type", choices=["decision", "fact", "lesson", "preference"], default="fact")

    # ingest
    p = sub.add_parser("ingest", help="Ingest session transcripts")
    p.add_argument("path")
    p.add_argument("--project", default=None, help="Filter to sessions from this project path")

    # prime
    p = sub.add_parser("prime", help="Output session-start context")
    p.add_argument("--wing", default=None)

    # status
    sub.add_parser("status", help="Show indexed content")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    # Auto-detect wing from cwd for add/prime (not search — search defaults to all projects)
    if hasattr(args, "wing") and args.wing is None and args.command in ("add", "prime"):
        args.wing = Path.cwd().name.replace("-", "_")

    commands = {"search": cmd_search, "add": cmd_add, "ingest": cmd_ingest, "prime": cmd_prime, "status": cmd_status}
    commands[args.command](args)


if __name__ == "__main__":
    main()
