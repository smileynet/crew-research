---
id: "152"
title: "handoff: secret-scan gate before finalizing (P3)"
status: in_progress
blocked_by: []
spec: "rider-skill-updates"
---

# handoff: secret-scan gate before finalizing (P3)

## Intent source

Rider AIA skill review (2026-09-17) — agentcraft-handoff's `validate_handoff.py` runs
14 secret regexes + a hard BLOCKED gate before accepting a handoff; crew-research's
handoff has none. Proposal: `.scratch/skill-update-exploration/PROPOSALS.md` (Rev 2, P3).
Evidence: `.scratch/proposal-research/secret-scanning.md`,
`.scratch/proposal-codebase/secret-handling.md`.

## Context

- **HANDOFF.md is git-TRACKED**: `.gitignore` has `.scratch/*` then `!.scratch/HANDOFF.md`
  (re-includes it) — a pasted token gets committed to history. (verified)
- **No secret scanner or owner exists anywhere** in the repo (`gitleaks`/`detect-secrets`
  = 0 matches). Coverage is adjacent, not overlapping: code-review checklist (review-time),
  mise-helper (storage/prevention), base-prompt safety_guardrails (don't echo values).
  A handoff-time scan fills the WRITE-TIME gap — no duplication.
- Handoff is deliberately **script-free** → implement as a PROSE gate (no Python validator,
  no runtime dep), matching the skill's grain.
- Post-rebase the handoff skill was restructured (in-flight delta shape, ticket 150) but the
  `## Quality Check` section and the "do not paste logs or transcripts" Rules bullet both
  survive — P3 anchors intact.

## What to build

1. Extend `## Quality Check` with a 4th point — scan the drafted handoff for credentials
   using the high-precision shortlist [L4, gitleaks/detect-secrets]:
   - AWS keys `(AKIA|ASIA|…)[A-Z0-9]{16}`, private-key header `-----BEGIN … PRIVATE KEY`,
     GitHub `gh[porsu]_…`/`github_pat_`, Slack `xox[baprs]-`, Stripe `sk_live_`,
     Google `AIza[0-9A-Za-z_\-]{35}`, `Authorization:`/`Bearer` headers, DSN inline
     passwords `://user:PASSWORD@host`.
   - Ignore obvious placeholders (`${VAR}`, `<token>`, `changeme`). On a real hit → replace
     the value with `<redacted: KEY_NAME>` and reference the secret by name.
   - Note: HANDOFF.md is git-tracked.
2. Add a Rules bullet after "do not paste logs or transcripts": never write secret VALUES;
   reference by name; the file is committed to git.

## Acceptance criteria

- [ ] `## Quality Check` has a 4th "no secrets" point with the concrete pattern shortlist + placeholder-ignore guidance
- [ ] Rules bullet added forbidding secret values (references-by-name)
- [ ] Redaction convention (`<redacted: KEY_NAME>`) stated
- [ ] Remains a prose gate — no script, no new runtime dependency
- [ ] `mise run validate` + `mise run lint` pass; `mise run generate -- kiro-cli` clean
- [ ] Skill stays coherent with the new in-flight-delta structure (no stale references to old sections)

## Out of scope

- A Python secret validator (deliberately prose-only)
- A repo-wide secret-hygiene skill/steering (if ever created, this gate should LINK to it — revisit trigger)
- Scanning anything other than the handoff at write time

## Revisit trigger

If a repo-wide secret-hygiene owner is created, replace the inline pattern list here with a
pointer to it (avoid duplicating the list in two places — Rule 6 one-owner).

- [ ] TBD
