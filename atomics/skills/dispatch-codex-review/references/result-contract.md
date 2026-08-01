# Codex Review Result Contract

Codex must end with exactly one single-line JSON result prefixed by
`CODEX_REVIEW_RESULT `.

Ticketed review:

```text
CODEX_REVIEW_RESULT {"run_id":"<uuid>","target":"<sha>","result":"ticketed","ticket":".tickets/<file>.md"}
```

Clean review:

```text
CODEX_REVIEW_RESULT {"run_id":"<uuid>","target":"<sha>","result":"clean","reviewed_through":"<sha>"}
```

The coordinator must compare exact values, fetch the remote, and verify the
remote-reachable artifacts. Process output is a locator, not proof.

## Invocation

Prefer the host's Codex subagent mechanism. CLI fallback:

```text
codex exec -C <repository> <prompt>
```

Apply only the minimum permissions needed for marker/ticket commits and pushes.
Do not pass repository content inline; Codex reads it from the working tree.
