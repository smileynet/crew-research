# Convention File Detection

When reviewing code or adopting a project, scan for ALL known AI convention files to
discover existing team rules. Use findings as additional review criteria or adoption context.

## Detection Script

```bash
bash tools/lint/detect-convention-files.sh <project-path>
```

Returns JSON array of found files with tool, scope, and format metadata.

## Known Convention Files

| Pattern | Tool | Format | Scope |
|---------|------|--------|-------|
| `AGENTS.md` | Universal (~20 tools) | Markdown | Root = project-wide; subdir = scoped |
| `CLAUDE.md` | Claude Code | Markdown | Root = project-wide; subdir = scoped |
| `GEMINI.md` | Gemini CLI | Markdown | Root = project-wide; subdir = scoped |
| `.cursorrules` | Cursor (legacy) | Plain text | Project root only |
| `.cursor/rules/*.mdc` | Cursor (current) | MDC (md + yaml frontmatter) | Per-file activation |
| `.windsurfrules` | Windsurf (legacy) | Plain text | Project root only |
| `.windsurf/rules/*.md` | Windsurf (current) | Markdown | Per-file |
| `.github/copilot-instructions.md` | GitHub Copilot | Markdown | Project-wide |
| `.github/instructions/*.instructions.md` | Copilot (scoped) | Markdown + `applyTo` | File-pattern |
| `.clinerules/*` | Cline | Markdown | Project-wide |
| `.rules/*` | Generic | Markdown | Project-wide |
| `.kiro/steering/*.md` | Kiro | Markdown + frontmatter | Project-wide |

## Priority for Code Review

When multiple convention files exist, use this priority:
1. `.kiro/steering/` (crew-research managed, authoritative)
2. `AGENTS.md` (cross-tool standard, project-level)
3. Tool-specific files (may contain tool-specific instructions not relevant to review)

Rules in higher-priority files override lower when they conflict.

## Excluded Paths

Detection skips: `.references/`, `vendor/`, `node_modules/`, `.git/`
These contain third-party code whose conventions shouldn't govern project review.

## Using Findings in Review

For each non-kiro convention file found:
1. Read the file content
2. Extract actionable rules (patterns to follow, things to avoid, naming conventions)
3. Add to the Standards axis review criteria alongside `.kiro/steering/` rules
4. Note the source when citing a finding: "Per CLAUDE.md: ..."
