---
id: "45"
title: "tkt pre-launch hardening: input validation + informative lost-race reporting"
status: open
blocked_by: []
env: either
spec: "ticket-cli"
---

# tkt pre-launch hardening: input validation + informative lost-race reporting

## What to build

Close the pre-launch hardening gaps found in the ticket-41 research sweep (spec R18 +
R19, added 2026-07-22). Research: `.scratch/research/cli-input-validation.md`,
`.scratch/research/concurrent-claim-semantics.md`.

1. **Slug validation (R18).** `tkt new <slug>` currently interpolates the slug straight
   into the filename — `tkt new ../../evil` writes outside `.tickets/`. Validate BEFORE
   any filesystem operation (the CVE-class root cause is validate-after-first-write):
   - allowlist `^[a-z0-9][a-z0-9-]*$` (both corpora verified: zero existing violations)
   - reject Windows reserved device names (CON, PRN, AUX, NUL, COM1-9, LPT1-9)
     case-insensitively and extension-blind, on all platforms (cargo's approach)
   - belt-and-braces: resolve the joined path and assert it stays under `.tickets/`
2. **Title/free-text escaping (R18).** Titles are double-quoted but not escaped — a
   title containing `"` produces frontmatter tkt itself cannot re-parse. Escape `\` and
   `"` on emit (new, edit); identifier-like fields (spec, env, priority) get charset
   validation instead.
3. **Informative lost-claim-race reporting (R19).** A lost `tkt claim` race currently
   dies with a raw rebase error. On push rejection: fetch, re-read the ticket, and if its
   status changed upstream report the winner's state ("tkt: lost claim race — 42 is
   already in_progress upstream") as a normal outcome with a clean exit, not a git
   stack-trace. (DynamoDB ALL_OLD failure-model; git push rejection is already the CAS.)

## Context

- Spec: `.memory/specs/ticket-cli-spec.md` R18 (MUST), R19 (SHOULD), R17 applies to all
  new behavior.
- Hostile fixtures from research: `../evil`, `con`, `NUL.md`-shaped slugs, `name.`,
  `foo: bar`, `on`, `1e3`, title with `"quote"` and backslash.
- Existing suite: `tools/tkt/tests/` (conftest repo_pair + run_tkt helpers).

## Acceptance criteria

- [ ] Hostile slugs rejected with a clear message BEFORE any file is created; the
      hostile-fixture set runs black-box (R17) and nothing lands outside `.tickets/`
- [ ] Round-trip property: any accepted `tkt new`/`tkt edit` output re-parses clean
      (`tkt validate` green immediately after creation with hostile-but-legal titles)
- [ ] Lost claim race reports winner state with exit 1 (contested outcome), not exit 2
      (crash); black-box test via pre-receive hook or competing clone
- [ ] Existing suite still green via `mise run test:tkt`

## Out of scope

- Version floor (R20 — COULD, trigger not met)
- Unicode normalization / superscript device-name variants (research open question;
  revisit if a real fixture appears)
