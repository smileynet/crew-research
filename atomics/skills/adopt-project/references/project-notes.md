# Project Notes Template

When adopting a brownfield project, captured special instructions go here. This file serves as a template for what to capture and where to place it.

## What to Capture

| Source | Capture | Placement |
|--------|---------|-----------|
| "Always run X before committing" | Verification command | `.crew-config.yaml` → `verify` |
| "Never use library Y" | Constraint | `.kiro/steering/project-rules.md` |
| "We call X by the name Z" | Terminology | `.memory/CONTEXT.md` |
| "Deploy requires steps A, B, C" | Process | `.kiro/skills/deploy/references/` or steering |
| "This pattern is intentional, not a bug" | Non-obvious gotcha | `.kiro/steering/project-rules.md` |
| "Use tabs/2-space/4-space" | Formatting | `.editorconfig` or steering |
| Architecture choice with rationale | Decision | `.memory/adr/NNNN-slug.md` |

## .crew-config.yaml Format

```yaml
build: "npm run build"
test: "npm test"
lint: "npm run lint"
verify: "npm run typecheck && npm test"
```

## .kiro/steering/project-rules.md Format

```markdown
# Project Rules

## Constraints
- Never import from `src/internal/` outside that directory
- All API responses use camelCase

## Conventions
- Feature branches: `feat/short-description`
- Components: PascalCase directories with index.ts barrel

## Gotchas
- The `auth` middleware must run before `rate-limit` (order matters in Express chain)
- `DATABASE_URL` must include `?sslmode=require` in production
```

## Checklist

After adoption, verify:
- [ ] All "always/never" rules captured in steering
- [ ] Build/test/lint commands in .crew-config.yaml
- [ ] Terminology in CONTEXT.md
- [ ] Reference repos documented in AGENTS.md
- [ ] Existing workflows preserved or mapped to crew equivalents
- [ ] Custom verification steps accessible to verification-protocol
