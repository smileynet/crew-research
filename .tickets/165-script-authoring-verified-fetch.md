---
id: "165"
title: "script-authoring: sha256-verified atomic cached fetch + proxy fallback (P5 ADD-TO)"
status: open
blocked_by: []
spec: "rider-followups"
---

# script-authoring: sha256-verified atomic cached fetch + proxy fallback

## Intent source

Rider review, openai-docs (SYNTHESIS pattern #8). Proposal:
`.scratch/new-skill-proposals-from-rider.md` P5. openai-docs' fetch script does HEAD+GET sha256
verification, atomic temp+rename caching, and curl↔fetch transport fallback preferring curl
under a proxy.

## What to build

Add a "Hardened remote fetch" pattern to `atomics/skills/script-authoring/SKILL.md`: when a
script fetches a remote resource — (1) write to a temp file then atomic-rename into place
(never a half-written cache); (2) verify integrity (sha256 against a known/served hash) where
available; (3) transport fallback (curl preferred under a corporate proxy, then a native
fetcher). Relevant to the corp-proxy / Bedrock environments crew-research supports.

## Acceptance criteria

- [ ] `script-authoring` gains a concise "Hardened remote fetch" pattern (atomic write, integrity check, proxy-tolerant transport)
- [ ] Names the corp-proxy/Bedrock relevance
- [ ] `mise run validate` + `mise run lint` pass; stays a pattern note, not a vendored script
- [ ] No duplication with existing script-authoring content

## Out of scope

- Vendoring an actual fetch script
