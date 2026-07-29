---
id: "70"
title: "Restore a second judge family on corp (codex sandbox fix or Bedrock non-Anthropic leg)"
status: open
blocked_by: []
env: corp
priority: high
spec: "eval-harness"
---

# Restore a second judge family on corp (codex sandbox fix or Bedrock non-Anthropic leg)

## What to build

Every corp run is currently a degraded panel: one Claude judge scoring Claude-produced
output (`panel.degraded: true`, reason `n=1 — single judge, no consensus`). ADR 0010's
cross-family floor needs ≥3 judges spanning ≥2 families, so at minimum one non-Anthropic
family has to come back.

Three candidate paths — pick on evidence, don't build all three:

1. **Repair the codex leg.** It fails before reaching a model:
   `codex-wrapper: error: failed to create temporary file for AWS config: Permission
   denied ... /home/<user>/.sbox-session/<id>/.tmp*`. Reproduces from any cwd, so it is
   an environment/permissions issue, not a harness bug. If fixable, this is the cheapest
   path and also unblocks pinning `gpt-5.6-sol` (currently left at tool default because
   the id cannot be verified — see judges/default.yaml).
2. **Non-Anthropic Bedrock leg via direct `invoke-model`.** Ticket 35's constraint list
   already flags this as spike-first. crush only surfaces Bedrock models it knows; a
   direct-invoke judge leg would be new harness code, so scope it deliberately.
3. **crush pointed at a non-Anthropic Bedrock model** via `CREW_CRUSH_JUDGE_MODEL`.
   Verify the model is actually reachable in account 563171622587/us-west-2 first —
   pointing crush at Bedrock *Claude* does NOT satisfy the floor (family is derived from
   the model id, and the harness will still report one family).

## Acceptance criteria

- [ ] A corp run reports `panel.degraded: false` with `families >= 2` in both meta.json
      and per-row `panel` objects
- [ ] The chosen path is recorded with why the other two were rejected (cost, scope, or
      reachability), in the ticket Resolution
- [ ] Judge tier policy respected: the new leg runs its family's frontier model, not a
      cheap tier (ADR 0010)
- [ ] `bash tools/evals/harness/test-panel.sh` still passes, extended with a case for the
      new leg's family derivation if a new vendor appears
- [ ] If the codex path is taken: `gpt-5.6-sol` verified live and pinned in
      judges/default.yaml, replacing the tool-default placeholder
