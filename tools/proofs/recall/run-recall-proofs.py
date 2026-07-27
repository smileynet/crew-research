#!/usr/bin/env python3
"""run-recall-proofs.py — Execute recall platform proofs (G-K series).

Each proof uses an isolated temp database (RECALL_DB env override) and
verifies a correctness invariant of the import/search pipeline.

Exit codes: 0 = all pass, 1 = one or more failed, 2 = crash.

NOTE: Must run with the Python that has recall's dependencies installed.
If recall is installed via `uv tool install -e ./tools/recall`, use:
  uv tool run --from recall python tools/proofs/recall/run-recall-proofs.py
"""

import importlib.util
import os
import sys
import tempfile
from pathlib import Path

# Fix Windows console encoding
if sys.platform == "win32":
    sys.stdout.reconfigure(errors="replace")
    sys.stderr.reconfigure(errors="replace")

# Suppress HuggingFace auth warnings
os.environ.setdefault("HF_HUB_VERBOSITY", "error")

PROOFS_DIR = Path(__file__).parent

# Ensure the recall package is importable (handles editable installs)
recall_src = PROOFS_DIR.parent.parent / "recall"
if recall_src.is_dir() and str(recall_src.parent) not in sys.path:
    sys.path.insert(0, str(recall_src.parent))


def discover_proofs() -> list[Path]:
    """Find all proof_*.py scripts in this directory."""
    return sorted(PROOFS_DIR.glob("proof_*.py"))


def run_proof(proof_path: Path) -> tuple[str, bool, str]:
    """Run a single proof in an isolated temp DB. Returns (name, passed, message)."""
    name = proof_path.stem.replace("proof_", "").upper()

    # Create isolated temp database
    tmp = tempfile.NamedTemporaryFile(suffix=".sqlite3", prefix=f"recall-proof-{name}-", delete=False)
    tmp.close()
    db_path = tmp.name

    try:
        # Inject RECALL_DB into environment before loading
        os.environ["RECALL_DB"] = db_path

        # Force recall.store to pick up the new RECALL_DB path.
        # The module caches DB_PATH at import time, so we must invalidate
        # it between proofs to get true DB isolation.
        if "recall.store" in sys.modules:
            sys.modules["recall.store"].DB_PATH = Path(db_path)

        # Load and execute the proof module
        spec = importlib.util.spec_from_file_location(proof_path.stem, proof_path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)

        # Each proof module exposes a run() -> (passed: bool, message: str)
        passed, message = mod.run()
        return name, passed, message
    except Exception as e:
        return name, False, f"CRASH: {e}"
    finally:
        # Cleanup
        os.environ.pop("RECALL_DB", None)
        try:
            os.unlink(db_path)
        except OSError:
            pass


def main():
    proofs = discover_proofs()
    if not proofs:
        print("No proof scripts found.", file=sys.stderr)
        sys.exit(2)

    print(f"\n  Recall Proofs — {len(proofs)} definitions\n")

    results = []
    for proof_path in proofs:
        name, passed, message = run_proof(proof_path)
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"  [{name}] {status}: {message}")
        results.append(passed)

    passed_count = sum(results)
    total = len(results)
    print(f"\n  Results: {passed_count}/{total} passed\n")

    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()
