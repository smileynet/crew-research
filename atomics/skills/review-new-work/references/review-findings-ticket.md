---
id: "<allocated-by-tkt>"
title: "Confirm and address review findings through <short-sha>"
status: open
blocked_by: []
priority: high
---

# Confirm and address review findings through <short-sha>

## Review provenance

- Reporter: <reviewer-id>
- Review run: `<run-id>`
- Review target: `<full-sha>`
- Review coverage: `<boundary-or-root>..<full-sha>`
- Confirmation status: unconfirmed

`Reporter:` is `Codex` for a single-reviewer run (the default), or
`aggregate (<reviewer>, <reviewer>, …)` for a multi-model matrix run. Keep the
`Confirmation status: unconfirmed` line verbatim — downstream steering
(frontier-work) matches it to force independent reproduction before editing.

These findings are reviewer hypotheses, not established defects. The agent
working this ticket must reproduce and confirm each finding against current code
before changing it. Multiple reviewers agreeing raises PRIORITY, not
confirmation — agreement is a prior, never proof, and never waives reproduction.

## Findings

Single-reviewer: omit the `Reviewers` / `Agreement` lines. Multi-model: include
them so the consumer can prioritise (verify consensus findings first) without
skipping reproduction on any.

### F1 — <severity>: <summary>

- Location: `<path:line>`
- Evidence: <observed code path or behavior>
- Risk: <why it matters>
- Suggested confirmation: <focused test or inspection>
- Reviewers: <reviewer-id>[, <reviewer-id>…]   # multi-model only
- Agreement: consensus | majority | single       # multi-model only
- Confidence: verified | inferred | tentative     # reviewer-scoped

## Acceptance criteria

- [ ] Every finding is independently marked confirmed, rejected, or obsolete
- [ ] Rejected or obsolete findings include evidence and rationale
- [ ] Confirmed findings are corrected
- [ ] Regression tests cover confirmed defects where practical
- [ ] Relevant build, test, and lint checks pass
- [ ] Corrected changes receive a fresh review
