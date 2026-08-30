---
id: "136"
title: "Fix known-tools.yaml broken repo paths and recall manifest/hydrate"
status: done
blocked_by: []
---

# Fix known-tools.yaml broken repo paths and recall manifest/hydrate

## What to build

TBD

## Acceptance criteria

- [x] TBD

## Resolution (2026-08-30)

Fixed archwright hydrate placeholder, corrected recall hydrate (deploy-local.sh not deploy-skills.sh), removed false manifest fields from recall+tkt (no SKILL_MANIFEST.yaml exists), added orchestration blocks to recall+tkt, documented CREW_TOOLS_ROOT probe order. Verified: yq parses orchestration, doctor.sh still detects, generate.sh validate passes.
