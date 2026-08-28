# Review Result Contract

Each reviewer must end with exactly one single-line JSON result prefixed by
`REVIEW_RESULT `. The `reviewer` field identifies which reviewer produced it
(`codex`, or `opencode/<provider>/<model>`) so a matrix coordinator can collect
N results per target.

Ticketed review:

```text
REVIEW_RESULT {"run_id":"<uuid>","reviewer":"<id>","target":"<sha>","result":"ticketed","ticket":".tickets/<file>.md"}
```

Clean review:

```text
REVIEW_RESULT {"run_id":"<uuid>","reviewer":"<id>","target":"<sha>","result":"clean","reviewed_through":"<sha>"}
```

Indeterminate (empty output, timeout, parse loss, quota-exhausted — the reviewer
could not complete):

```text
REVIEW_RESULT {"run_id":"<uuid>","reviewer":"<id>","target":"<sha>","result":"indeterminate","reason":"<timeout|empty|quota|parse_error>"}
```

The coordinator must compare exact values, fetch the remote, and verify the
remote-reachable artifacts. Process output is a locator, not proof. **An
indeterminate result (or a missing/degraded one) is NOT clean** — it is a
coverage gap and must be reported/denied, never treated as a pass. Service
degradation is not a reason to allow.

## Invocation

Prefer the host's subagent mechanism. CLI fallbacks:

```text
# Codex (default reviewer)
codex exec --dangerously-bypass-approvals-and-sandbox <prompt>

# opencode (single model or one per matrix entry)
opencode run --auto -m <provider>/<model> <prompt>
```

The bypass/auto flag is required. Without it the reviewer's sandbox/permission
gate blocks subprocess execution (project verification commands like `cargo
test`, `godot --headless`, etc.) and git push, producing false review results or
failing to commit the findings ticket.

Only dispatch reviews in environments where the repository is trusted and
network access is acceptable (CI runners, local dev machines).

Do not pass repository content inline; the reviewer reads it from the working tree.

## Reviewer identity in artifacts

- Findings ticket provenance: `- Reporter: <reviewer-id>` (was `Codex`).
- Per-finding confidence: `- <reviewer-id> confidence: verified | inferred | tentative`.
- Review marker (`.review/review-marker.json`): each `reviewers[]` entry carries
  its `reviewer` id and coverage boundary. On first read, migrate a legacy
  `.codex/review-marker.json` (schema 1) by wrapping its fields as
  `reviewer:"codex"`.
