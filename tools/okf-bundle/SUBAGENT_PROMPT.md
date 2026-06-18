# OKF Bundle Generation — Subagent Prompt

You are analyzing a reference repository to produce an OKF (Open Knowledge Format) bundle.
The bundle captures structured knowledge about the repo for future agent consumption.

## Source Repository

Name: `{name}`
Path: `{path}`

## Key Files to Read

{key_files}

## Skills Found

{skill_files}

## Your Task

Produce OKF concept documents for this repo. Each concept is a markdown file with YAML frontmatter.

### Required Output

Write the following files to `.memory/references/{name}/`:

1. **`overview.md`** — type: Repository
   - Purpose, architecture, key decisions
   - Who uses it, what problems it solves
   - Cross-link to patterns and conventions below

2. **`patterns/*.md`** — type: Pattern (one file per novel technique)
   - Only document patterns worth adopting in other projects
   - Include implementation details and source file references
   - Skip generic/obvious patterns

3. **`conventions/*.md`** — type: Convention (one file per local rule)
   - Document rules that differ from common practice
   - Include rationale and source references

4. **`integrations/*.md`** — type: Integration (one file per connection point)
   - How this repo's ideas connect to our project
   - What we'd adopt vs adapt

5. **`index.md`** — root listing of all concepts

### Frontmatter Format

```yaml
---
type: Repository | Pattern | Convention | Integration
title: Short display name
description: One sentence summary (used in index.md)
resource: path/to/key/source/file (optional)
tags: [relevant, keywords]
timestamp: {timestamp}
---
```

### Body Format

- Use structural markdown (headings, lists, code blocks)
- Cross-link between concepts with relative paths: `[name](../patterns/foo.md)`
- End each concept with `# Citations` linking to specific source files

### Rules

- Be concrete — cite specific files, quote specific patterns
- Skip generic observations (don't say "well-organized code")
- Focus on what's novel, non-obvious, or adoptable
- Keep each concept doc under 100 lines
- Only create concepts that have genuine value; 3 good patterns > 10 trivial ones
