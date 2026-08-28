---
id: "131"
title: "codex CLI 0.147.0 can't serve a usable model (gpt-5.6-sol needs newer CLI; gpt-5.1-codex rejected on ChatGPT auth)"
status: backlog
blocked_by: []
validation_criteria:
  - "codex exec produces a findings run on this machine; ticket 130 Phase 3 regression completes"
---

# codex CLI 0.147.0 can't serve a usable model (gpt-5.6-sol needs newer CLI; gpt-5.1-codex rejected on ChatGPT auth)

## Context

Discovered during ticket 130 Phase 3 (Codex-default regression check for dispatch-review).
`codex exec` runs and authenticates, but no usable model is available on this machine:

- **Default `gpt-5.6-sol`**: `400 invalid_request_error — "The 'gpt-5.6-sol' model requires a newer version of Codex. Please upgrade to the latest app or CLI and try again."` (installed: codex-cli 0.147.0)
- **`-m gpt-5.1-codex`**: `400 invalid_request_error — "The 'gpt-5.1-codex' model is not supported when using Codex with a ChatGPT account."`

This blocks the codex reviewer path in dispatch-review (and any codex leg in eval/proof
harnesses) on this machine. NOT a dispatch-review bug — the invocation is correct.

## What to do

1. Upgrade codex CLI (`winget install --id OpenAI.Codex` or `npm i -g @openai/codex`) to a version that supports `gpt-5.6-sol`, OR
2. Identify a model id that IS available on the current ChatGPT-account auth and pin it (`-m <id>` or codex config `model=`), OR
3. Switch codex auth to an API-key account that permits the codex models.
4. Then complete ticket 130 Phase 3: run the codex reviewer against the planted-review fixture and confirm a valid contract-compliant findings run.

## Acceptance criteria

- [ ] codex exec produces a clean findings run (real findings + REVIEW_RESULT) on this machine
- [ ] The usable model id / required CLI version is documented (tool-installation guide)
- [ ] Ticket 130 Phase 3 Codex regression completes and is re-graded by the judge panel
