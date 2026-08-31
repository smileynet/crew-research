#!/usr/bin/env python3
"""Confusion matrix for data-modeling corpus evals (ticket 147).

The judged harness emits only per-task 1-5 scores, not detection rates. This
reads scores.jsonl, thresholds each task's with-skill avg to caught/missed,
and tallies a confusion matrix using a per-def label map (task index -> expected
FLAG or PASS).

Task-score semantics (both label kinds use the same criteria convention):
  - FLAG task: high score = correctly flagged the invalid state (true positive).
  - PASS task: high score = correctly did NOT fabricate a finding (true negative).
So a task "passes its own intent" when avg >= THRESHOLD regardless of label; the
confusion matrix then attributes it to TP/TN (correct) or FN/FP (wrong) by label.

Usage:
  python3 confusion-matrix.py <scores.jsonl> <def-name>
Exit: 0 always (reporting tool); prints JSON summary + human table.
"""
import json
import sys

THRESHOLD = 3.0  # avg >= this = the task met its intent (matches def threshold)

# Per-def label maps: task index (0-based, def task order) -> ("FLAG"|"PASS", short-name).
# Keep in sync with the task order in each definition file.
LABELS = {
    "data-modeling-illegal-states-effectiveness": [
        ("FLAG", "synthetic-order-flags"),
        ("PASS", "synthetic-feature-flags-no-refactor"),
        ("PASS", "tkt-status-enum"),
        ("PASS", "recall-decision-enum"),
        ("PASS", "bigg-pi-result-union"),
        ("PASS", "bigg-pi-runphase"),
        ("FLAG", "recall-searchresult-strings"),
        ("FLAG", "recall-telemetryconfig-bools"),
        ("FLAG", "bigg-pi-hardgates"),
        ("FLAG", "tkt-config-stringly"),
    ],
    "data-modeling-corpus-holdout": [
        ("PASS", "tkt-consent-enum"),
        ("PASS", "tkt-publishresult"),
        ("PASS", "bigg-pi-capabilities"),
        ("FLAG", "tkt-planentry"),
        ("FLAG", "line-cook-errortype"),
    ],
}


def load_def(scores_path, def_name):
    with open(scores_path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip().lstrip("\ufeff")
            if not line:
                continue
            row = json.loads(line)
            if row.get("name") == def_name:
                return row
    return None


def with_skill_task_avgs(row):
    """task index -> with-skill avg."""
    out = {}
    for ts in row.get("task_scores", []):
        if ts.get("condition") == "with-skill":
            out[ts["task"]] = ts.get("avg")
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 0
    scores_path, def_name = sys.argv[1], sys.argv[2]
    labels = LABELS.get(def_name)
    if labels is None:
        print(json.dumps({"status": "error", "errors": [f"no label map for {def_name}"]}))
        return 0
    row = load_def(scores_path, def_name)
    if row is None:
        print(json.dumps({"status": "error", "errors": [f"{def_name} not in {scores_path}"]}))
        return 0

    avgs = with_skill_task_avgs(row)
    tp = fp = tn = fn = err = 0
    rows = []
    for idx, (label, name) in enumerate(labels):
        avg = avgs.get(idx)
        if avg is None:
            outcome = "ERR"  # all trials errored/empty — exclude from the matrix
            err += 1
            rows.append({"idx": idx, "task": name, "label": label, "avg": avg, "outcome": outcome})
            continue
        met = avg >= THRESHOLD  # task met its own intent
        # met + FLAG = correctly flagged (TP); met + PASS = correctly didn't fabricate (TN)
        # !met + FLAG = missed a real smell (FN); !met + PASS = fabricated a finding (FP)
        if label == "FLAG":
            outcome = "TP" if met else "FN"
        else:
            outcome = "TN" if met else "FP"
        tp += outcome == "TP"
        fp += outcome == "FP"
        tn += outcome == "TN"
        fn += outcome == "FN"
        rows.append({"idx": idx, "task": name, "label": label, "avg": avg, "outcome": outcome})

    precision = tp / (tp + fp) if (tp + fp) else None
    recall = tp / (tp + fn) if (tp + fn) else None  # TPR over FLAG items
    fp_rate = fp / (fp + tn) if (fp + tn) else None  # over-application rate on PASS items
    f1 = (2 * precision * recall / (precision + recall)
          if precision and recall else None)

    summary = {
        "status": "pass" if fn == 0 and fp == 0 else "fail",
        "def": def_name,
        "metrics": {
            "TP": tp, "FP": fp, "TN": tn, "FN": fn, "ERR": err,
            "precision": precision, "recall_TPR": recall,
            "false_positive_rate": fp_rate, "f1": f1,
        },
        "errors": [],
    }
    print(json.dumps(summary, indent=2))
    print("\n idx  outcome  avg   label  task")
    for r in rows:
        print(f"  {r['idx']:>2}  {r['outcome']:<7} {str(r['avg']):>4}  {r['label']:<4}  {r['task']}")
    print(f"\n TPR(recall)={recall} precision={precision} FP-rate={fp_rate} F1={f1}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
