---
id: "60"
title: "Recall import: source key collision fix (wing-scoped keys)"
status: open
blocked_by: []
env: either
spec: "recall-import-fix"
---

# Recall import: source key collision fix (wing-scoped keys)

## What to build

Include the wing name in import source keys so that identically-named files across different projects don't collide on the idempotency check.

## Context

- **Observed (2026-07-26):** `recall import .memory/ --wing lacrosse_bosse_agentic` reports "92 skipped (already filed)" despite that wing having 0 chunks. The source key `import:adr/0001-something.md` from crew_research's earlier import satisfies the existence check for lacrosse_bosse_agentic's file at the same relative path.
- **Root cause:** Source key format is `import:{relative_path}` — no wing scoping. Two projects with `adr/0001-foo.md` collide.
- **Current key:** `import:adr/0001-practice-skill-cross-linking.md`
- **Proposed key:** `import:crew_research:adr/0001-practice-skill-cross-linking.md`

## Design

1. Change source key format to `import:{wing}:{relative_path}`
2. The idempotency check (`SELECT 1 FROM drawers WHERE source = ?`) now correctly scopes per-wing
3. **Migration:** Existing rows need their source keys updated: `UPDATE drawers SET source = 'import:' || wing || ':' || SUBSTR(source, 8) WHERE source LIKE 'import:%' AND source NOT LIKE 'import:%:%'`
4. The `--force` DELETE already scopes by wing (ticket 52), so no change needed there

## Acceptance criteria

- [ ] Source keys include wing: `import:{wing}:{relative_path}`
- [ ] Two projects with identically-named files both get imported (no collision)
- [ ] Existing import data is migrated to the new key format (schema migration)
- [ ] Idempotency still works: importing the same project twice skips correctly
- [ ] `--force` still correctly clears only the target wing's imports
- [ ] `recall import` without `--wing` (auto-derived) produces the same key format

## Out of scope

- Changing session ingest source keys (they already include the session UUID — no collision risk)
- Deduplicating genuinely identical content across wings (ticket 55 territory)
