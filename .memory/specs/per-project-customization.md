# Per-Project Customization

## How Projects Declare Commands

Projects declare build/test/lint commands in their `AGENTS.md` Commands section:

```markdown
## Commands

```bash
# Build
npm run build

# Test
npm test

# Lint
npm run lint
```
```

The agent discovers these at runtime via the AGENTS.md Commands section or by detecting config files (see `project-checks.md` for the discovery order).

## What It Does

1. **Project metadata** — name, language (detected from AGENTS.md, README, or config files)
2. **Verification commands** — declared in AGENTS.md Commands section; skills consult these to know how to check work
3. **Knowledge injection** — steering pointers inject domain context into skills at runtime (ADR 0002)

## What It Doesn't Do

- Domain knowledge injection → use steering pointers (ADR 0002)
- Skill behavioral changes → use extends (local skill shadows shared)

## Minimal Example

Add a Commands section to your project's `AGENTS.md`:

```markdown
## Commands

```bash
npm test
```
```

## Resolution Order

```
1. Local skill (project's .kiro/skills/) — wins completely
2. Shared skill + steering pointers — injected context
3. Shared skill with defaults — fallback
```
