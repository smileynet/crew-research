#!/usr/bin/env python3
"""multi-project-import-eval.py — Validate recall import across diverse project types.

Tests:
1. Import scales across multiple projects (different domains, sizes, structures)
2. Frontmatter parsing works for OKF-formatted files (type, title, tags)
3. Wing/room derivation is correct per project
4. Cross-project queries stay scoped (wing isolation)
5. Within-project queries find the right files

Run: ~/.local/share/uv/tools/recall/bin/python tools/evals/scripts/multi-project-import-eval.py
"""

import json
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "recall"))

from recall import chunker, embedder, store
from recall.cli import _parse_frontmatter

FIXTURES_DIR = Path(__file__).resolve().parent.parent / "fixtures" / "import-samples"

# Projects to import (dirname → expected wing)
PROJECTS = {
    "sci-phoenix": {"wing": "sci_phoenix", "expected_rooms": {"specs", "adr", "general"}},
    "asset-production": {"wing": "asset_production", "expected_rooms": {"guides", "plans", "general"}},
    "shadowrun-sega": {"wing": "shadowrun_sega", "expected_rooms": {"hardware", "general"}},
    "pixelrig": {"wing": "pixelrig", "expected_rooms": {"general"}},
    "okf-bundle": {"wing": "okf_bundle", "expected_rooms": {"tables", "metrics"}},
}

# Queries with expected source file and wing
QUERIES = [
    {
        "query": "How does the SCI mechanical interpreter flat heap model work?",
        "expected_source": "specs/mechanical-interpreter.md",
        "expected_wing": "sci_phoenix",
    },
    {
        "query": "What is the save restore file format for SCI games?",
        "expected_source": "specs/save-restore.md",
        "expected_wing": "sci_phoenix",
    },
    {
        "query": "Which OPL2 emulator was chosen and why?",
        "expected_source": "adr/0002-nuked-opl3.md",
        "expected_wing": "sci_phoenix",
    },
    {
        "query": "How does the PBR texture pipeline decision tree work?",
        "expected_source": "guides/pbr-pipeline.md",
        "expected_wing": "asset_production",
    },
    {
        "query": "What is QUASAR quality scoring?",
        "expected_source": "CONTEXT.md",
        "expected_wing": "asset_production",
    },
    {
        "query": "How does the Genesis 68000 power on and fetch vectors?",
        "expected_source": "genesis-execution-model.md",
        "expected_wing": "shadowrun_sega",
    },
    {
        "query": "What are the YM2612 register write timing constraints?",
        "expected_source": "hardware/z80-ym2612-timing.md",
        "expected_wing": "shadowrun_sega",
    },
    {
        "query": "What MCU does PixelRig use and what is the display resolution?",
        "expected_source": "CONTEXT.md",
        "expected_wing": "pixelrig",
    },
    {
        "query": "How does the DMA2D sprite blitting pipeline work per frame?",
        "expected_source": "display-pipeline.md",
        "expected_wing": "pixelrig",
    },
    {
        "query": "What fields are in the GA4 events BigQuery table?",
        "expected_source": "tables/events.md",
        "expected_wing": "okf_bundle",
    },
    {
        "query": "How is average transactions per purchaser calculated?",
        "expected_source": "metrics/avg-transactions-per-purchaser.md",
        "expected_wing": "okf_bundle",
    },
    {
        "query": "What is the Stack Overflow users table schema?",
        "expected_source": "tables/users.md",
        "expected_wing": "okf_bundle",
    },
]


def import_project(conn, project_dir: Path, wing: str) -> dict:
    """Import a single project's .md files. Returns stats."""
    md_files = sorted(project_dir.rglob("*.md"))
    md_files = [f for f in md_files if f.name != "index.md"]

    total_chunks = 0
    files_imported = 0
    frontmatter_found = 0

    for md_file in md_files:
        rel_path = md_file.relative_to(project_dir)
        source_key = f"import:{rel_path}"

        text = md_file.read_text(encoding="utf-8", errors="replace")
        if not text.strip():
            continue

        title, type_ = _parse_frontmatter(text)
        if type_:
            frontmatter_found += 1
        else:
            type_ = "document"

        chunks = chunker.chunk_markdown(text)
        if not chunks:
            continue

        parts = list(rel_path.parts)
        room = parts[0] if len(parts) > 1 else "general"

        embeddings = embedder.embed_documents(chunks)
        rows = []
        for chunk, emb in zip(chunks, embeddings):
            rows.append({
                "content": chunk,
                "embedding": emb,
                "wing": wing,
                "room": room,
                "type": type_,
                "source": source_key,
                "source_file": str(rel_path),
            })

        store.upsert_batch(conn, rows)
        total_chunks += len(chunks)
        files_imported += 1

    return {
        "files": files_imported,
        "chunks": total_chunks,
        "frontmatter_parsed": frontmatter_found,
    }


def run_queries(conn) -> dict:
    """Run queries with wing-scoped and unscoped search."""
    results = {"scoped": [], "unscoped": []}

    for q in QUERIES:
        query_emb = embedder.embed_query(q["query"])

        # Scoped to expected wing
        scoped = store.search(conn, query_emb, q["query"], wing=q["expected_wing"], n_results=5)
        scoped_found = None
        for i, r in enumerate(scoped):
            if r.get("source_file") and q["expected_source"] in r["source_file"]:
                scoped_found = i + 1
                break

        # Unscoped (all wings)
        unscoped = store.search(conn, query_emb, q["query"], n_results=5)
        unscoped_found = None
        unscoped_correct_wing = False
        for i, r in enumerate(unscoped):
            if r.get("source_file") and q["expected_source"] in r["source_file"]:
                unscoped_found = i + 1
                break
        if unscoped:
            unscoped_correct_wing = unscoped[0].get("wing") == q["expected_wing"]

        results["scoped"].append({
            "query": q["query"],
            "expected": q["expected_source"],
            "wing": q["expected_wing"],
            "found_at": scoped_found,
            "top_source": scoped[0].get("source_file") if scoped else None,
        })
        results["unscoped"].append({
            "query": q["query"],
            "found_at": unscoped_found,
            "top_wing_correct": unscoped_correct_wing,
            "top_source": unscoped[0].get("source_file") if unscoped else None,
        })

    return results


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Multi-project import eval")
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    # Isolated temp DB
    with tempfile.NamedTemporaryFile(suffix=".sqlite3", delete=False, prefix="recall-multi-eval-") as f:
        db_path = Path(f.name)

    os.environ["RECALL_DB"] = str(db_path)
    import importlib
    importlib.reload(store)

    try:
        conn = store.get_connection()

        # Import all projects
        print("  Importing projects...", file=sys.stderr)
        import_stats = {}
        for name, meta in PROJECTS.items():
            project_dir = FIXTURES_DIR / name
            if not project_dir.is_dir():
                print(f"  WARNING: {project_dir} not found, skipping", file=sys.stderr)
                continue
            stats = import_project(conn, project_dir, meta["wing"])
            import_stats[name] = stats
            print(f"  {name}: {stats['files']} files, {stats['chunks']} chunks, {stats['frontmatter_parsed']} with frontmatter", file=sys.stderr)

        total_drawers = conn.execute("SELECT COUNT(*) FROM drawers").fetchone()[0]
        print(f"  Total: {total_drawers} drawers", file=sys.stderr)

        # Verify room derivation
        print("\n  Checking wing/room structure...", file=sys.stderr)
        room_check_pass = True
        for name, meta in PROJECTS.items():
            rows = conn.execute(
                "SELECT DISTINCT room FROM drawers WHERE wing = ?", (meta["wing"],)
            ).fetchall()
            actual_rooms = {r[0] for r in rows}
            if not meta["expected_rooms"].issubset(actual_rooms):
                missing = meta["expected_rooms"] - actual_rooms
                print(f"  FAIL {name}: missing rooms {missing}", file=sys.stderr)
                room_check_pass = False
            else:
                print(f"  OK {name}: rooms={sorted(actual_rooms)}", file=sys.stderr)

        # Run queries
        print("\n  Running queries...", file=sys.stderr)
        query_results = run_queries(conn)
        conn.close()

        # Score
        n = len(QUERIES)
        scoped_at_1 = sum(1 for r in query_results["scoped"] if r["found_at"] == 1) / n
        scoped_at_3 = sum(1 for r in query_results["scoped"] if r["found_at"] and r["found_at"] <= 3) / n
        unscoped_at_3 = sum(1 for r in query_results["unscoped"] if r["found_at"] and r["found_at"] <= 3) / n
        wing_precision = sum(1 for r in query_results["unscoped"] if r["top_wing_correct"]) / n

        # Frontmatter check: OKF files should have been parsed
        okf_fm = import_stats.get("okf-bundle", {}).get("frontmatter_parsed", 0)
        okf_files = import_stats.get("okf-bundle", {}).get("files", 0)
        frontmatter_pass = okf_fm == okf_files and okf_fm > 0

        output = {
            "import_stats": import_stats,
            "total_drawers": total_drawers,
            "scores": {
                "scoped_recall_at_1": scoped_at_1,
                "scoped_recall_at_3": scoped_at_3,
                "unscoped_recall_at_3": unscoped_at_3,
                "wing_precision": wing_precision,
            },
            "checks": {
                "room_derivation": "PASS" if room_check_pass else "FAIL",
                "frontmatter_parsing": "PASS" if frontmatter_pass else "FAIL",
                "okf_frontmatter_count": f"{okf_fm}/{okf_files}",
            },
            "verdict": "PASS" if (scoped_at_3 >= 0.75 and room_check_pass and frontmatter_pass) else "FAIL",
        }

        if args.verbose:
            output["query_details"] = query_results

        print(json.dumps(output, indent=2))

        if output["verdict"] == "FAIL":
            sys.exit(1)

    finally:
        db_path.unlink(missing_ok=True)
        db_path.with_suffix(".sqlite3-wal").unlink(missing_ok=True)
        db_path.with_suffix(".sqlite3-shm").unlink(missing_ok=True)


if __name__ == "__main__":
    main()
