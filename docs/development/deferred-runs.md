# Deferred Runs — Owed-Run Ledger

Evals that cannot run on every machine. When `run.sh` SKIPs a def (adapter scoping or
failed access probe), the run it owes is recorded here. Results are gitignored, so this
committed ledger is the cross-machine coordination point: a machine with the required
access picks up owed runs, executes them, and fills in the `filled` column.

Principle (extension protocol): gaps are pending-with-reason, never silent.

## How to use

- **Adding a row:** when you scope a def with `adapters:` (or see it SKIP), add it here
  with the reason and date.
- **Filling a row:** run the def on a machine with access
  (`bash tools/evals/harness/run.sh --adapter <adapter> --definition <name>`), then record
  the run timestamp + commit in `filled`. Keep the row (history), don't delete it.
- Environment access map: `.memory/grill/ticket-open-questions/Q01-access-map.md`
  (corp = no agy, crush via Bedrock/Claude-only; personal = full access).

## Ledger

| Def (id) | Required adapter | Reason | Owed since | Filled |
|----------|------------------|--------|------------|--------|
| image-greedy-tool-detection | crush (personal env) | Def premise is GLM-5.2's missing vision; corp crush runs Claude (has vision), breaking the designed behavioral delta. Birth run owed. | 2026-07-19 | — |
| image-multi-validator-consensus | crush (personal env) | Same premise as above — GLM-5.2 no-vision required. Birth run owed. | 2026-07-19 | — |
| image-no-vision-honesty | crush (personal env) | Same premise as above — GLM-5.2 no-vision required. Birth run owed. | 2026-07-19 | — |
