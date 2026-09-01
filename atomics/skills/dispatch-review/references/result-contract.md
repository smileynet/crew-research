# Review Result Contract

Each reviewer must end with exactly one single-line JSON result prefixed by
`REVIEW_RESULT `. The `reviewer` field identifies which reviewer produced it
(`codex`, `opencode/<provider>/<model>`, or `agy/<model>`) so a matrix
coordinator can collect N results per target.

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

# agy / Google Antigravity CLI (Gemini family, matrix leg when on PATH)
#   --print is a GREEDY value flag: attach the prompt as --print="..." and keep
#   --dangerously-skip-permissions elsewhere, or agy swallows the flag as the prompt.
#   Validate by result.status=="SUCCESS" (terminal event:"result"), not exit code.
agy --dangerously-skip-permissions --model <gemini-model> --output-format stream-json --print="<prompt>"
```

The bypass/auto flag is required (`--dangerously-bypass-approvals-and-sandbox` /
`--auto` / `--dangerously-skip-permissions`). Without it the reviewer's sandbox/permission
gate blocks subprocess execution (project verification commands like `cargo
test`, `godot --headless`, etc.) and git push, producing false review results or
failing to commit the findings ticket.

Only dispatch reviews in environments where the repository is trusted and
network access is acceptable (CI runners, local dev machines).

Do not pass repository content inline; the reviewer reads it from the working tree.

## Reviewer identity in artifacts (two-layer provenance)

Keep two layers — do NOT collapse them (a collapsed "codex+kimi" reporter
destroys the agreement signal a consumer needs):

- **Top-level** findings-ticket `Reporter:` = `Codex` for a single reviewer, or
  `aggregate (<id>, <id>, …)` for a multi-model matrix run.
- **Per-finding** `Reviewers: <id>[, <id>…]` + `Agreement: consensus | majority |
  single` (multi-model only) — records which reviewers raised each finding.
- Per-finding `Confidence: verified | inferred | tentative` is reviewer-scoped.
- Keep `Confirmation status: unconfirmed` verbatim (frontier-work matches it).
  Agreement raises reproduction PRIORITY, never confirmation — reproduction is
  never waived, even for consensus findings.
- Review marker (`.review/review-marker.json`): each `reviewers[]` entry carries
  its `reviewer` id and coverage boundary. On first read, migrate a legacy
  `.codex/review-marker.json` (schema 1) by wrapping its fields as
  `reviewer:"codex"`.

See the producer template: `../review-new-work/references/review-findings-ticket.md`.
