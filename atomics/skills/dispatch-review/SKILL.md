---
name: dispatch-review
description: "Dispatch one or more independent reviewers (Codex, or opencode with a model matrix) to review all unreviewed repository work, then verify each correlated findings ticket or clean result. Use when requesting an independent review, auditing all changes, checking work since the last review, running a multi-model review, or waiting for reviewer findings. Trigger: dispatch review, dispatch codex review, independent review, multi-model review, review all changes, check review findings, run review agent, opencode review."
metadata:
  type: process
  invocation: both
  practice: null
---

# Dispatch Review

Run one or more independent reviewers and accept only correlated, committed results. Reviewer is a parameter: **codex** (default) or **opencode/<model>** (single or matrix). The fail-closed gate lives here, in the coordinator — reviewers only produce results; they cannot weaken the contract.

## Reviewers

| Reviewer | Invocation | Result prefix |
|----------|-----------|---------------|
| `codex` (default) | `codex exec --dangerously-bypass-approvals-and-sandbox <prompt>` | `REVIEW_RESULT ` |
| `opencode/<provider>/<model>` | `opencode run --auto -m <provider>/<model> <prompt>` | `REVIEW_RESULT ` |

`--dangerously-bypass-approvals-and-sandbox` (codex) / `--auto` (opencode) are **required** — without them the reviewer's sandbox/permission gate blocks subprocess execution (tests, linters, `godot --headless`) and git push, producing false results. Only dispatch in trusted repos where network access is acceptable. See [references/result-contract.md](references/result-contract.md); model-matrix and quota handling in [references/model-matrix.md](references/model-matrix.md).

## Prepare

1. Read project instructions and the `review-new-work` skill.
2. Require a Git repository and record `TARGET = git rev-parse HEAD`.
3. Generate a unique `RUN_ID`; do not use ticket ordering as correlation. For a matrix, one shared `RUN_ID` + per-reviewer sub-id (`<RUN_ID>/<provider-model-slug>`).
4. Record existing committed ticket paths and the current review marker (`.review/review-marker.json`, migrating from `.codex/` on first read).
5. Stop if unrelated dirty changes would make the review target ambiguous.

## Dispatch

Launch each reviewer in the repository with this task (prefer the host's subagent facility; CLI is the fallback):

```text
Use review-new-work to review all uncovered work through TARGET=<full sha>.
Review run id: RUN_ID=<uuid>[/<reviewer-slug>]. Do not apply fixes. On findings,
create and push the required high-priority aggregate ticket. Return the exact
result contract line. Tag findings with Reviewer=<reviewer-id>.
```

**Matrix mode:** dispatch one reviewer per model, each in its own `mktemp -d` workdir (eval-execution containment). Reviewers write per-model findings; the parent (main context) does the fan-in — one aggregate ticket, deduped by location+category, tiered by agreement (Consensus/Majority/Individual), tagged per model. If a model is quota-exhausted (see `coding-plan-limits`), it degrades the run (continue with remaining models, report the gap) — it does not fail the whole review.

## Verify (fail-closed — per reviewer)

1. Require a successful reviewer process and parse its final `REVIEW_RESULT` line (includes a `reviewer` field).
2. Fetch the remote before inspecting tickets.
3. For `ticketed`: find exactly one committed, remote-reachable ticket containing the exact run id. Verify `priority: high`, target, coverage, reviewer provenance, and `Confirmation status: unconfirmed`.
4. For `clean`: require no ticket containing the run id and verify the remote-reachable marker covers the target.
5. For `indeterminate` (empty output, timeout, parse-loss, quota-exhausted): treat as **NOT clean** — deny/report the coverage gap. Service degradation is never a pass.
6. Re-read the ticket from the fetched commit; do not trust stdout or a working-tree-only file.
7. Report per-reviewer: ticket path + summary, clean target + marker boundary, or the indeterminate gap.

Fail closed on missing/duplicate tickets, mismatched targets, unpushed state, an absent/unpushed clean marker, malformed output, empty/degraded reviewer output, or a newer unrelated ticket mistaken for the result. Preserve artifacts and explain how to resume.

## Scope

Does NOT review code, confirm findings, apply fixes, or choose frontier work. Uses `review-new-work` for review methodology, `coding-plan-limits` for reviewer quota/capacity handling, and `frontier-work` to consume resulting tickets.
