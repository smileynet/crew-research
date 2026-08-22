---
name: dispatch-codex-review
description: "Dispatch Codex to review all unreviewed repository work, then verify its correlated findings ticket or clean result. Use when requesting an independent Codex review, auditing all changes, checking work since the last review, or waiting for Codex findings. Trigger: dispatch codex review, independent review, review all changes, check codex findings, run review agent."
metadata:
  type: process
  invocation: both
  practice: null
---

# Dispatch Codex Review

Run an independent Codex review and accept only a correlated, committed result.

## Prepare

1. Read project instructions and the `review-new-work` skill.
2. Require a Git repository and record `TARGET = git rev-parse HEAD`.
3. Generate a unique `RUN_ID`; do not use ticket ordering as correlation.
4. Record existing committed ticket paths and the current review marker.
5. Stop if unrelated dirty changes would make the review target ambiguous.

## Dispatch

Launch Codex in the repository with this task:

```text
Use review-new-work to review all uncovered work through TARGET=<full sha>.
Review run id: RUN_ID=<uuid>. Do not apply fixes. On findings, create and push
the required high-priority aggregate ticket. Return the exact result contract.
```

**Invocation (CLI fallback):**

```bash
codex exec --dangerously-bypass-approvals-and-sandbox "Use review-new-work to review all uncovered work through TARGET=<sha>. Review run id: RUN_ID=<uuid>. Do not apply fixes. On findings, create and push the required high-priority aggregate ticket. Return the exact result contract."
```

The `--dangerously-bypass-approvals-and-sandbox` flag is **required**. Without
it, Codex's sandbox blocks subprocess execution (test commands, linters, `godot
--headless`, etc.) and Git push — producing false review results or failing to
commit the findings ticket.

Use the environment's Codex subagent facility when available; the CLI command
above is the fallback. See [references/result-contract.md](references/result-contract.md).

## Verify

1. Require a successful Codex process and parse its final result contract.
2. Fetch the remote before inspecting tickets.
3. For `ticketed`, find exactly one committed, remote-reachable ticket containing
   the exact run id. Verify `priority: high`, target, coverage, Codex provenance,
   and `Confirmation status: unconfirmed`.
4. For `clean`, require no ticket containing the run id and verify the
   remote-reachable marker covers the target.
5. Re-read the ticket from the fetched commit; do not trust stdout or a working-tree-only file.
6. Report the ticket path and summary, or the clean target and marker boundary.

Fail closed on missing or duplicate tickets, mismatched targets, unpushed state,
an absent or unpushed clean marker, malformed output, or a newer unrelated ticket mistaken
for the result. Preserve artifacts and explain how to resume.

## Scope

Does NOT review code, confirm findings, apply fixes, or choose frontier work.
Use review-new-work for review and frontier-work to consume the resulting ticket.
