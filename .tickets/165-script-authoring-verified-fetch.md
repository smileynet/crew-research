---
id: "165"
title: "script-authoring: sha256-verified atomic cached fetch + proxy fallback (P5 ADD-TO)"
status: done
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

- [x] `script-authoring` gains a concise "Hardened remote fetch" pattern (atomic write, integrity check, proxy-tolerant transport)
- [x] Names the corp-proxy/Bedrock relevance
- [x] `mise run validate` + `mise run lint` pass; stays a pattern note, not a vendored script
- [x] No duplication with existing script-authoring content

## Out of scope

- Vendoring an actual fetch script

## Resolution (2026-09-19)

Added Hardened Remote Fetch pattern to script-authoring (atomic temp+rename, sha256 integrity check, curl-preferred proxy-tolerant transport; cross-refs source-authority freshness ladder; corp-proxy/Bedrock relevance noted). Pattern note, no vendored script. validate + lint 0/0. Commit 9627043.
