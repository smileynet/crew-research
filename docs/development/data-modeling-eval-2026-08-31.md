# data-modeling eval — build complete, execution blocked (ticket 147)

Date: 2026-08-31

## Status

**Artifacts complete and validated. Eval EXECUTION is blocked by an environment
mismatch** between the eval harness (Linux-native) and this machine (Windows kiro-cli
driven through a minimal Fedora WSL). Tuning against live projects awaits a run on a
Linux-native machine (or a harness Windows-interop adapter). Details below.

## What was built (committed)

| Artifact | Purpose |
|----------|---------|
| `tools/evals/definitions/activation-data-modeling.yaml` | 5 positive / 5 negative activation tasks (gates TPR≥0.5, FPR≤0.2) |
| `tools/evals/definitions/data-modeling-illegal-states-effectiveness.yaml` | Tuning set: 2 synthetic + 8 real corpus structures (dual-run, threshold 3.0, delta −0.5) |
| `tools/evals/definitions/data-modeling-corpus-holdout.yaml` | Held-out set: 5 real structures, NEVER tuned against (generalization signal / overfit guard) |
| `tools/evals/scripts/confusion-matrix.py` | Reads `scores.jsonl` `task_scores[]` with-skill avgs → per-item TP/FP/TN/FN + precision/recall/FP-rate/F1 |

All three defs parse (`yq`), the script compiles (`py_compile`), and the effectiveness
def passes the harness `--dry-run` ("would run", adapter probe accepted at dry-run level).

## Live-project corpus (real structures, labeled)

Mined read-only from repos on this machine. 13 candidates total, split 8 tuning / 5 holdout,
stratified across PASS/FLAG. No Go exists on this machine; corpus is Rust + TypeScript + Python.

Tuning set (8): tkt `Status`, recall `Decision`, bigg-pi `Result<T>`, bigg-pi `RunPhase` (PASS);
recall `SearchResult`, recall `TelemetryConfig`, bigg-pi `hardGates`, tkt `Config` (FLAG; last two
are borderline over-flag calibration items).
Holdout set (5): tkt `ConsentReason`, tkt `PublishResult`, bigg-pi capabilities `as const` (PASS);
tkt `PlanEntry`, line-cook `LoopError` (FLAG).

## The execution blocker (confirmed via multiple approaches)

The eval harness assumes a Linux-native environment where kiro-cli, `sqlite3`, and the
session DB are all locally present. This machine has none of that layout:

1. **Adapter probe fails** — `tools/proofs/adapters/kiro-cli.yaml` invokes `kiro-cli`
   (bare). Inside WSL only `kiro-cli.exe` exists (Windows binary). A PATH wrapper
   forwarding to the `.exe` failed: WSL→Windows-exe arg marshalling passed an empty
   subcommand (`error: unrecognized subcommand ''`). So `run.sh` SKIPs every def with
   "adapter kiro-cli: no access (probe failed)".
2. **Activation harness needs `sqlite3` CLI** (absent — minimal Fedora WSL has no package
   manager) **and reads `$HOME/.local/share/kiro-cli/data.sqlite3`** (XDG path), but the
   real DB is at `/mnt/c/Users/uosmi/AppData/Local/Kiro-Cli/data.sqlite3` (Windows AppData).
   A Python-backed `sqlite3` shim + a symlink were attempted; the shim's nested-quote SQL
   marshalling through `wsl -- bash -c` was unreliable.
3. **Background execution does not survive** — `setsid nohup ... &` inside `wsl -- bash -c`
   dies when the `wsl.exe` invocation returns (the WSL session tears down its process
   tree). Verified: even a trivial detached loop left no log. This defeats the
   eval-execution steering's background-run model on this host.

Root cause: one environment, three compounding Linux-native assumptions. Not a defect in
the defs or the skill.

## Activation evidence (interim, field-proven)

Ticket 146's activation smoke-check already passed on this machine: a headless
`kiro-cli chat --agent-engine v2` on the `held:bool/sold:bool` prompt produced the skill's
exact create-side guidance (invalid-state table, discriminated union with state-carrying
variants, per-language TS/Rust/Python, transition + DB-boundary concerns, clarifying
questions rather than over-modeling). So the skill activates and behaves correctly; what's
blocked is the *harness-scored, quantified* activation + effectiveness run.

## What unblocks it

Run on a Linux-native machine (or WSL with a full toolchain) where kiro-cli, `sqlite3`,
and the session DB are natively present:

```bash
mise run eval:activation                 # activation-data-modeling → TPR/FPR
setsid nohup bash tools/evals/harness/run.sh \
  --definition data-modeling-illegal-states-effectiveness --adapter kiro-cli \
  > /tmp/dm-eff.log 2>&1 < /dev/null &     # then the holdout def the same way
# after each: python3 tools/evals/scripts/confusion-matrix.py \
#   tools/evals/results/<ts>/scores.jsonl <def-name>
```

Then tune SKILL.md / review-lens.md from **tuning-set** FP/FN only; report the **holdout**
confusion matrix separately as the generalization signal. Honest target per the calibration
research: real review tools score 33–47% F1 — favor precision (low over-flag rate) over recall.

## AC status

- [x] Both eval defs created and runnable (dry-run accepted; runtime blocked by env, not defs)
- [x] Live-project corpus assembled (13 real structures, multi-language, PASS/FLAG mix)
- [ ] Review mode scored over the corpus — BLOCKED (harness can't drive kiro-cli in this env)
- [ ] Skill tuned from FP/FN — BLOCKED (depends on scores)
- [ ] Activation gates pass — activation behavior field-proven (146); harness TPR/FPR BLOCKED
- [x] Results recorded (this doc)
