"""Run all embedding spikes and produce a comparison table."""

import json
import subprocess
import sys
from pathlib import Path

SPIKE_DIR = Path(__file__).parent
SCRIPTS = [
    "spike_a_minilm.py",
    "spike_b_nomic.py",
    "spike_c_embeddinggemma.py",
    "spike_d_snowflake.py",
    "spike_e_qwen3.py",
    "spike_f_mxbai.py",
]


def main():
    print("=" * 70)
    print("  RECALL EMBEDDING SPIKE — Running all 6 models")
    print("=" * 70)

    for script in SCRIPTS:
        path = SPIKE_DIR / script
        print(f"\n>>> Running {script}...")
        result = subprocess.run(
            [sys.executable, str(path)],
            cwd=str(SPIKE_DIR),
            capture_output=False,
        )
        if result.returncode != 0:
            print(f"  WARNING: {script} exited with code {result.returncode}")

    # Collect results
    print("\n" + "=" * 70)
    print("  COMPARISON TABLE")
    print("=" * 70)

    results = []
    for f in sorted(SPIKE_DIR.glob("results_*.json")):
        results.append(json.loads(f.read_text()))

    if not results:
        print("  No results found. Check individual spike outputs above.")
        return

    # Header
    print(f"\n{'Model':<30} {'Size':>6} {'Dim':>5} {'Chunks':>7} {'Ingest':>8} {'R@3':>5} {'p50':>6} {'p95':>6}")
    print("-" * 80)

    for r in sorted(results, key=lambda x: -x["recall_at_3"]):
        print(
            f"{r['model']:<30} "
            f"{r['install_size_mb']:>5}M "
            f"{r['dimension']:>5} "
            f"{r['chunks_ingested']:>7} "
            f"{r['ingest_time_s']:>7.1f}s "
            f"{r['recall_at_3']:>4.0%} "
            f"{r['query_latency_p50_ms']:>5}ms "
            f"{r['query_latency_p95_ms']:>5}ms"
        )

    # Write combined results
    combined = SPIKE_DIR / "results_combined.json"
    combined.write_text(json.dumps(results, indent=2))
    print(f"\n  Combined results: {combined}")


if __name__ == "__main__":
    main()
