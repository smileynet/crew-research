# Per-Project Customization

## Format: `.crew-config.yaml`

Projects place a `.crew-config.yaml` at their root to declare project metadata and verification commands.

```yaml
# .crew-config.yaml — project-level customization
project: my-rust-cli
language: rust

# Verification commands (skills use these to check work)
verification:
  build: "cargo check"
  test: "cargo test"
  lint: "cargo clippy --all-targets -- -D warnings"

# Params injected into skills that declare them
params:
  verification-protocol:
    build_command: "cargo check"
    test_command: "cargo test"
    lint_command: "cargo clippy -- -D warnings"
  git-protocol:
    branch_strategy: "feature-branch"
```

## What It Does

1. **Project metadata** — name, language (used by init/adopt for detection)
2. **Verification commands** — skills consult these to know how to check work in this project
3. **Param injection** — values substituted into skills that declare `params:` in frontmatter

## What It Doesn't Do

- Domain knowledge injection → use steering pointers (ADR 0002)
- Skill behavioral changes → use extends (local skill shadows shared)
- Crew/archetype selection → removed (skills-only deployment, ADR 0003)

## Minimal Example

```yaml
project: my-app
language: typescript
verification:
  test: "npm test"
```

## Resolution Order

```
1. Local skill (project's .kiro/skills/) — wins completely
2. Shared skill + project params — substituted values
3. Shared skill with defaults — fallback
```
